"""Zephyr-style iterative join demo: persist a large immutable table and
re-join a changing frontier against it across K rounds without re-shuffling.

Models the core pain from issue #6997: a large static edge table
``DIR_EDGE`` is repeatedly joined against a small evolving frontier
across K dependent rounds of a driver loop. With no persistence, each
round pays the full read cost. A ``Persist`` walker simulates caching
the big table once, then ``DriverLoop`` repeatedly joins the frontier
against the resident dataset.
"""

# ---------- Edge archetypes ----------

edge PersistsAs {
    has storage_tier: str = "MEMORY_AND_DISK";
    has shards: int = 0;
}

edge JoinsAgainst {
    has round: int = 0;
    has scanned_bytes: int = 0;
    has probed_bytes: int = 0;
}

edge FrontierLink {
    has round: int = 0;
}

# ---------- Node archetypes ----------

node DirEdge {
    has src: str = "";
    has dst: str = "";
    has size_bytes: int = 0;
}

node Frontier {
    has label: str = "";
    has round: int = 0;
    has members: list[str] = [];
}

node CacheHandle {
    has name: str = "";
    has storage_tier: str = "MEMORY_AND_DISK";
    has shards: int = 0;
    has resident_bytes: int = 0;
    has pinned: bool = True;
    has evicted: bool = False;
}

# ---------- Walker: materialize + pin the big table once ----------

walker Persist {
    has handle_name: str = "DIR_EDGE_CACHE";
    has storage_tier: str = "MEMORY_AND_DISK";

    can start with Root entry {
        print(f"[persist] materializing {self.handle_name} tier={self.storage_tier}");
        visit [-->];
    }

    can ingest with DirEdge entry {
        # Each shard lands in the cache; we collapse all shards into one
        # resident handle to mirror "one logical table, many shards".
        visit [-->];
    }

    can finish with CacheHandle entry {
        print(f"[persist] pinned handle={here.name} "
              f"shards={here.shards} resident={here.resident_bytes}B");
        visit [-->];
    }
}

# ---------- Walker: simulate the K-round driver loop ----------

walker DriverLoop {
    has rounds: int = 3;
    has total_scanned: int = 0;
    has total_probed: int = 0;
    has pinned_seen: bool = False;

    can start with Root entry {
        print(f"[driver] K={self.rounds} rounds; persisting big table once");
        visit [-->];
    }

    can cache_ready with CacheHandle entry {
        self.pinned_seen = here.pinned;
        for k in range(self.rounds) {
            scanned = 0 if here.pinned else here.resident_bytes;
            probed = (k + 1) * 12;
            self.total_scanned = self.total_scanned + scanned;
            self.total_probed = self.total_probed + probed;
            label = "PINNED" if here.pinned else "UNPINNED";
            print(f"[round {k}] {label} scanned={scanned}B probed={probed}B");
        }
        here.evicted = True;
        here.pinned = False;
        visit [-->];
    }

    can note with DirEdge entry {
        # DriverLoop visits the big table for inspection; in a real
        # engine the join would stream against the cached handle.
        visit [-->];
    }
}

with entry {
    # Build DIR_EDGE as a connected chain of shards off root.
    root ++> DirEdge(src="a", dst="x", size_bytes=10_000)
         ++> DirEdge(src="b", dst="y", size_bytes=10_000)
         ++> DirEdge(src="c", dst="z", size_bytes=10_000)
         ++> DirEdge(src="x", dst="p", size_bytes=10_000)
         ++> DirEdge(src="y", dst="q", size_bytes=10_000)
         ++> DirEdge(src="z", dst="r", size_bytes=10_000);

    # One CacheHandle node holds the resident materialized state.
    root ++> CacheHandle(name="DIR_EDGE_CACHE",
                         storage_tier="MEMORY_AND_DISK",
                         shards=6,
                         resident_bytes=60_000,
                         pinned=True,
                         evicted=False);

    # Materialize once, then drive K rounds against the resident cache.
    root spawn Persist(handle_name="DIR_EDGE_CACHE",
                       storage_tier="MEMORY_AND_DISK");
    driver = DriverLoop(rounds=3);
    root spawn driver;
    print(f"driver totals: scanned={driver.total_scanned}B "
          f"probed={driver.total_probed}B "
          f"cache.evicted=True");
}
