"""Harness: exercise DerivedCache.invalidate, assert post-state, exit 0."""
from rec_24_cache_invalidate_downstream import DerivedCache


def build():
    """Fixture:

    raw --derived--> agg --derived--> report
                     agg --derived--> dashboard (dashboard also from metrics)
    metrics --derived--> dashboard   (diamond: two paths reach dashboard)
    config (independent)
    """
    cache = DerivedCache()
    cache.put("raw", [1, 2])
    cache.put("metrics", [3])
    cache.put("agg", 3)
    cache.put("report", "r")
    cache.put("dashboard", "d")
    cache.put("config", True)
    cache.declare("raw", "agg")
    cache.declare("agg", "report")
    cache.declare("agg", "dashboard")
    cache.declare("metrics", "dashboard")
    return cache


def test_invalidates_full_closure_with_diamond_once():
    cache = build()
    removed = cache.invalidate("raw")
    # diamond: dashboard reachable via agg twice AND via metrics, dropped once
    assert removed == ["agg", "dashboard", "raw", "report"], removed
    assert not cache.has("raw") and not cache.has("agg")
    assert not cache.has("dashboard") and not cache.has("report")
    assert cache.has("metrics") and cache.has("config")
    assert cache.value_of("config") is True


def test_unknown_key_and_stale_refs_tolerated():
    cache = build()
    assert cache.invalidate("nope") == []
    cache.store["agg"].dependents.append("ghost")     # stale declaration
    removed = cache.invalidate("agg")
    assert removed == ["agg", "dashboard", "report"]
    assert cache.has("metrics") and cache.has("config")  # survivors intact


def test_leaf_invalidation_keeps_upstream_alive():
    cache = build()
    assert cache.invalidate("report") == ["report"]
    assert cache.keys() == ["agg", "config", "dashboard", "metrics",
                            "raw"]


if __name__ == "__main__":
    test_invalidates_full_closure_with_diamond_once()
    test_unknown_key_and_stale_refs_tolerated()
    test_leaf_invalidation_keeps_upstream_alive()
    print("rec_24 ref harness: all assertions passed")
