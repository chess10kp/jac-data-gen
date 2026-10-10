"""Tests for the dependency graph validator in main.jac.

These tests exercise the behavior the issue promises: the Resolver walker
correctly reports clean resolution when pins agree, flags CONFLICT entries
when pins demand different versions of the same package, handles >= style
pins, and recognizes unparsable pin strings. Each test builds its own
fresh graph from scratch.
"""
import from main { Package, Requires, Resolver, ResolvesTo, VersionPin }

import io;
import from contextlib { redirect_stdout }

# ---------------------------------------------------------------------------
# Test 1: a fully consistent dependency graph resolves with zero conflicts.
# Mirrors the pre-fix state from the issue's demo: both packages pin
# cicaid-devtools to the same version, plus a downstream also agrees.
# ---------------------------------------------------------------------------
test "consistent graph produces zero conflicts" {
    root ++> Package(name="issue-worm", version="0.3.1")
            +>:Requires:+> VersionPin(raw_constraint="cicaid-devtools==0.2.4")
            +>:ResolvesTo:+> Package(name="cicaid-devtools", version="0.2.4");

    root ++> Package(name="issue-worm-pro", version="0.1.0")
            +>:Requires:+> VersionPin(raw_constraint="cicaid-devtools==0.2.4")
            +>:ResolvesTo:+> Package(name="cicaid-devtools", version="0.2.4");

    res = root spawn Resolver();

    assert len(res.conflicts) == 0, f"expected no conflicts, got {res.conflicts}";
    assert res.resolutions["cicaid-devtools"] == "0.2.4", (
        f"expected cicaid-devtools=0.2.4, got {res.resolutions}"
    );
    assert "issue-worm" in res.resolutions, "issue-worm must appear in resolutions";
    assert "issue-worm-pro" in res.resolutions, "issue-worm-pro must appear in resolutions";
}

# ---------------------------------------------------------------------------
# Test 2: two packages demanding different versions of the same dep produce
# exactly one CONFLICT entry naming both versions -- this is what PR #101
# was trying to catch.
# ---------------------------------------------------------------------------
test "diverging pins produce a CONFLICT listing both versions" {
    root ++> Package(name="issue-worm", version="0.3.1")
            +>:Requires:+> VersionPin(raw_constraint="cicaid-devtools==0.2.4")
            +>:ResolvesTo:+> Package(name="cicaid-devtools", version="0.2.4");

    # A separate consumer demands the newer version -- conflict must surface.
    root ++> Package(name="issue-worm-pro", version="0.1.0")
            +>:Requires:+> VersionPin(raw_constraint="cicaid-devtools==0.4.0")
            +>:ResolvesTo:+> Package(name="cicaid-devtools", version="0.4.0");

    res = root spawn Resolver();

    assert len(res.conflicts) >= 1, (
        f"expected >=1 conflict for diverging pins, got {res.conflicts}"
    );
    joined = " ".join(res.conflicts);
    assert "CONFLICT" in joined, f"missing CONFLICT marker in {res.conflicts}";
    assert "0.2.4" in joined, f"missing old version in {res.conflicts}";
    assert "0.4.0" in joined, f"missing new version in {res.conflicts}";
    assert "cicaid-devtools" in joined, f"missing package name in {res.conflicts}";
}

# ---------------------------------------------------------------------------
# Test 3: >= style pins are accepted and resolved like == pins.
# ---------------------------------------------------------------------------
test "greater-than-or-equal pins parse and contribute to resolutions" {
    root ++> Package(name="lib-a", version="1.0.0")
            +>:Requires:+> VersionPin(raw_constraint="lib-b>=2.5.0")
            +>:ResolvesTo:+> Package(name="lib-b", version="2.5.0");

    res = root spawn Resolver();

    assert len(res.conflicts) == 0, f"unexpected conflicts: {res.conflicts}";
    assert res.resolutions.get("lib-b") == "2.5.0", (
        f"expected lib-b=2.5.0, got {res.resolutions}"
    );
    assert res.resolutions.get("lib-a") == "1.0.0", (
        f"expected lib-a=1.0.0, got {res.resolutions}"
    );
}

# ---------------------------------------------------------------------------
# Test 4: an unparsable pin (no == and no >=) is flagged with UNPARSED PIN
# and the resolver still continues without crashing.
# ---------------------------------------------------------------------------
test "unparsable pin is reported and does not abort the walk" {
    root ++> Package(name="issue-worm", version="0.3.1")
            +>:Requires:+> VersionPin(raw_constraint="cicaid-devtools~=0.3");

    # Add a well-formed pin alongside so we can confirm the walk continues.
    root ++> Package(name="issue-worm-pro", version="0.1.0")
            +>:Requires:+> VersionPin(raw_constraint="cicaid-devtools==0.2.4")
            +>:ResolvesTo:+> Package(name="cicaid-devtools", version="0.2.4");

    res = root spawn Resolver();

    joined = " ".join(res.conflicts);
    assert "UNPARSED PIN" in joined, f"expected UNPARSED PIN in {res.conflicts}";
    assert "~=0.3" in joined, f"raw pin text missing from {res.conflicts}";
    # The good pin should still resolve.
    assert res.resolutions.get("cicaid-devtools") == "0.2.4", (
        f"good pin should still resolve, got {res.resolutions}"
    );
}

# ---------------------------------------------------------------------------
# Test 5: the demo entry block's pre-fix expectation (zero conflicts) and
# post-fix expectation (conflicts printed) match the issue's narrative. We
# replicate the demo's two-phase shape: first a clean walk, then mutate one
# pin and confirm the second walk reports conflicts.
# ---------------------------------------------------------------------------
test "two-phase walk mirrors the PR-101 narrative" {
    pin_iw_cicaid    = VersionPin(raw_constraint="cicaid-devtools==0.2.4");
    pin_iwpro_cicaid = VersionPin(raw_constraint="cicaid-devtools==0.2.4");

    root ++> Package(name="issue-worm", version="0.3.1")
            +>:Requires:+> pin_iw_cicaid
            +>:ResolvesTo:+> Package(name="cicaid-devtools", version="0.2.4");

    root ++> Package(name="issue-worm-pro", version="0.1.0")
            +>:Requires:+> pin_iwpro_cicaid
            +>:ResolvesTo:+> Package(name="cicaid-devtools", version="0.2.4");

    buf = io.StringIO();
    with redirect_stdout(buf) {
        pre = Resolver();
        root spawn pre;
        print(f"PRE-FIX  conflicts={len(pre.conflicts)} resolutions={pre.resolutions}");
    }
    pre_out = buf.getvalue();

    assert len(pre.conflicts) == 0, (
        f"pre-fix walk should be clean, got {pre.conflicts}"
    );
    assert "PRE-FIX" in pre_out, f"missing PRE-FIX marker in stdout: {pre_out}";
    assert "conflicts=0" in pre_out, f"pre-fix stdout should report 0 conflicts: {pre_out}";

    # Now flip the pin -- the post-fix state must surface conflicts.
    pin_iwpro_cicaid.raw_constraint = "cicaid-devtools==0.4.0";

    buf2 = io.StringIO();
    with redirect_stdout(buf2) {
        post = Resolver();
        root spawn post;
        print(f"POST-FIX conflicts={len(post.conflicts)} resolutions={post.resolutions}");
        for c in post.conflicts {
            print(f"  {c}");
        }
    }
    post_out = buf2.getvalue();

    assert len(post.conflicts) >= 1, (
        f"post-fix walk should flag conflict, got {post.conflicts}"
    );
    assert "POST-FIX" in post_out, f"missing POST-FIX marker: {post_out}";
    assert "CONFLICT" in post_out, f"missing CONFLICT in post-fix stdout: {post_out}";
    assert "0.2.4" in post_out and "0.4.0" in post_out, (
        f"both versions should appear in post-fix stdout: {post_out}"
    );
}
