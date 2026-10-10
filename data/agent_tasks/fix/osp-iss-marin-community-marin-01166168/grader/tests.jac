"""Test annex for the Zephyr persist + driver-loop demo.

Verifies the behavior the issue promises:

  * Persist pins the big table once and reports shard count + tier.
  * DriverLoop over a pinned cache costs 0 bytes re-scanned across K
    rounds (the whole point of ``persist()``).
  * An UNPINNED cache forces the driver to pay ``resident_bytes`` per
    round (the failure mode the issue is trying to escape).
  * After the loop runs, the handle is marked ``evicted`` and
    ``pinned=False`` (release path).
"""
import from main { CacheHandle, DirEdge, DriverLoop, Persist }

import io;
import from contextlib { redirect_stdout }

# ---------- helpers ----------

def make_graph {
    root spawn here;  # touch root so we can build under it
    return here;
}

# ---------- tests ----------

test "persist walker reports shard count, resident bytes, and tier" {
    root ++> DirEdge(src="a", dst="x", size_bytes=10_000)
         ++> DirEdge(src="b", dst="y", size_bytes=10_000)
         ++> DirEdge(src="c", dst="z", size_bytes=10_000)
         ++> DirEdge(src="x", dst="p", size_bytes=10_000)
         ++> DirEdge(src="y", dst="q", size_bytes=10_000)
         ++> DirEdge(src="z", dst="r", size_bytes=10_000);

    h = root ++> CacheHandle(name="DIR_EDGE_CACHE",
                             storage_tier="MEMORY_AND_DISK",
                             shards=6,
                             resident_bytes=60_000,
                             pinned=True,
                             evicted=False);

    buf = io.StringIO();
    with redirect_stdout(buf) {
        root spawn Persist(handle_name="DIR_EDGE_CACHE",
                           storage_tier="MEMORY_AND_DISK");
    }
    out = buf.getvalue();

    assert "[persist] materializing DIR_EDGE_CACHE" in out, f"missing materialization line: {out!r}";
    assert "[persist] pinned handle=DIR_EDGE_CACHE" in out, f"missing pin line: {out!r}";
    assert "shards=6" in out, f"shards count missing/wrong: {out!r}";
    assert "resident=60000B" in out, f"resident byte count missing/wrong: {out!r}";
    assert h.shards == 6, f"handle.shards should mirror DirEdge count, got {h.shards}";
    assert h.resident_bytes == 60_000, f"handle.resident_bytes should be 6 * 10000, got {h.resident_bytes}";
    assert h.storage_tier == "MEMORY_AND_DISK", f"default storage tier must be MEMORY_AND_DISK, got {h.storage_tier}";
}

test "driver loop over pinned cache scans zero bytes per round" {
    root ++> DirEdge(src="a", dst="x", size_bytes=10_000)
         ++> DirEdge(src="b", dst="y", size_bytes=10_000)
         ++> DirEdge(src="c", dst="z", size_bytes=10_000);

    h = root ++> CacheHandle(name="DIR_EDGE_CACHE",
                             shards=3,
                             resident_bytes=30_000,
                             pinned=True,
                             evicted=False);

    buf = io.StringIO();
    with redirect_stdout(buf) {
        d = DriverLoop(rounds=3);
        root spawn d;
    }
    out = buf.getvalue();

    # The whole point of persist(): K rounds must NOT re-read the big
    # table from storage.  Pinned ⇒ scanned == 0 every round.
    assert d.total_scanned == 0, (
        f"pinned cache must scan 0 bytes across K rounds, got {d.total_scanned}"
    );

    # Per-round print must show PINNED + scanned=0B three times.
    pinned_count = out.count("PINNED");
    assert pinned_count == 3, f"expected 3 PINNED round lines, got {pinned_count}: {out!r}";
    assert "scanned=0B" in out, f"pinned rounds must print scanned=0B: {out!r}";

    # Probed bytes grow linearly with round: (k+1)*12, k=0..2 → 12,24,36.
    assert d.total_probed == 12 + 24 + 36, (
        f"probed bytes should sum to 12+24+36=72 across 3 rounds, got {d.total_probed}"
    );
}

test "unpinned cache forces the driver to re-scan resident_bytes each round" {
    # No DirEdge shards needed — we only exercise the unpinned branch
    # of DriverLoop, which ignores them.
    h = root ++> CacheHandle(name="DIR_EDGE_CACHE",
                             shards=3,
                             resident_bytes=30_000,
                             pinned=False,    # not pinned → fail-open / re-scan
                             evicted=False);

    buf = io.StringIO();
    with redirect_stdout(buf) {
        d = DriverLoop(rounds=4);
        root spawn d;
    }
    out = buf.getvalue();

    # Unpinned ⇒ each round re-scans the full resident table.
    assert d.total_scanned == 4 * 30_000, (
        f"unpinned cache must re-scan resident_bytes every round: "
        f"4 * 30000 = 120000, got {d.total_scanned}"
    );
    assert "UNPINNED" in out, f"unpinned rounds must print UNPINNED: {out!r}";
    assert "scanned=30000B" in out, f"unpinned rounds must report full re-scan: {out!r}";

    # Per-round probed bytes still grow: (k+1)*12 for k=0..3 → 12,24,36,48.
    assert d.total_probed == 12 + 24 + 36 + 48, (
        f"probed bytes should sum to 120 across 4 rounds, got {d.total_probed}"
    );
}

test "driver loop marks the handle evicted and unpinned after running" {
    root ++> DirEdge(src="a", dst="x", size_bytes=10_000);

    h = root ++> CacheHandle(name="DIR_EDGE_CACHE",
                             shards=1,
                             resident_bytes=10_000,
                             pinned=True,
                             evicted=False);

    buf = io.StringIO();
    with redirect_stdout(buf) {
        d = DriverLoop(rounds=2);
        root spawn d;
    }

    assert h.evicted is True, f"handle should be evicted after driver loop, got {h.evicted}";
    assert h.pinned is False, f"handle should be unpinned after driver loop, got {h.pinned}";
    assert d.pinned_seen is True, f"driver should have observed pinned=True on entry, got {d.pinned_seen}";
}
