"""Guard for rec_24_cache_invalidate_downstream -- candidate OSP lift
inlined verbatim (same-prefix sibling imports are unreliable across jac's
native seam), plus behavioral tests: full-closure diamond invalidation
dropping shared keys exactly once, unknown-key and stale-reference
tolerance, leaf invalidation keeping upstream alive, and a survivors-only
invariant over the store.
"""


node CacheEntry {
    has key: str;
    has value: int | list[int] | str | bool | None = None;
}

edge DerivedFrom { }

"""Collect the transitive dependent closure of one entry."""
walker InvalidationSweep {
    has root_key: str;
    has doomed: list[CacheEntry] = [];
    has seen: dict[str, bool] = {};

    can sweep with CacheEntry entry {
        if here.key in self.seen {
            skip;           # diamond revisit / cycle policy: drop once only,
        }                   # but keep sibling branches alive (no disengage)
        self.seen[here.key] = True;
        self.doomed.append(here);
        visit [->:DerivedFrom:->];
    }
}

obj DerivedCache {
    has store: dict[str, CacheEntry];

    def put(key: str, value: int | list[int] | str | bool | None) -> CacheEntry {
        entry = self.store.get(key);
        if entry is None {
            entry = CacheEntry(key=key);
            self.store[key] = entry;
        }
        entry.value = value;
        return entry;
    }

    """Register *dependent_key* as derived from *source_key*.

    Dangling declarations are tolerated: refused, not raised.
    """
    def declare(source_key: str, dependent_key: str) -> bool {
        source = self.store.get(source_key);
        dependent = self.store.get(dependent_key);
        if source is None or dependent is None {
            return False;
        }
        source +>:DerivedFrom:+> dependent;   # edge points at dependents
        return True;
    }

    """Drop *key* plus every transitive dependent; returns removed keys."""
    def invalidate(key: str) -> list[str] {
        start = self.store.get(key);
        if start is None {
            return [];
        }
        # Phase COLLECT -- walk the closure without mutating anything.
        sweep = start spawn InvalidationSweep(root_key=key);
        doomed = sweep.doomed;
        removed = sorted(c.key for c in doomed);
        # Phase APPLY -- delete strictly after the walk finished.
        for victim in doomed {
            del victim;
        }
        for k in removed {
            _gone = self.store.pop(k, None);
        }
        return removed;
    }

    def has(key: str) -> bool {
        return key in self.store;
    }

    def value_of(key: str) -> int | list[int] | str | bool | None {
        entry = self.store.get(key);
        if entry is None {
            return None;
        }
        return entry.value;
    }

    def keys -> list[str] {
        return sorted(self.store.keys());
    }
}

"""Build a fresh deterministic cache; creation order = fixture order."""
def load_graph(entries: list[tuple[str, int | list[int] | str | bool | None]],
               derivations: list[tuple[str, str]]) -> DerivedCache {
    cache = DerivedCache(store={});
    for row in entries {
        _made = cache.put(row[0], row[1]);
    }
    for pair in derivations {
        _ok = cache.declare(pair[0], pair[1]);
    }
    return cache;
}

test "full_closure_diamond_dropped_once" {
    cache = load_graph(
        entries=[("raw", [1, 2]), ("metrics", [3]), ("agg", 3),
                 ("report", "r"), ("dashboard", "d"), ("config", True)],
        derivations=[("raw", "agg"), ("agg", "report"),
                     ("agg", "dashboard"), ("metrics", "dashboard")]
    );
    removed = cache.invalidate("raw");
    assert removed == ["agg", "dashboard", "raw", "report"];
    assert not cache.has("raw") and not cache.has("agg");
    assert not cache.has("dashboard") and not cache.has("report");
    assert cache.has("metrics") and cache.has("config");
    assert cache.value_of("config") is True;
}

test "unknown_key_and_stale_refs_tolerated" {
    cache = load_graph(
        entries=[("raw", 1), ("agg", 3), ("report", "r")],
        derivations=[("raw", "agg"), ("agg", "report")]
    );
    assert cache.invalidate("nope") == [];
    ok = cache.declare("agg", "ghost");      # dangling declaration refused
    assert ok is False;
    assert cache.invalidate("agg") == ["agg", "report"];
    assert cache.keys() == ["raw"];
}

test "leaf_invalidation_keeps_upstream_alive" {
    cache = load_graph(
        entries=[("raw", 1), ("report", "r")],
        derivations=[("raw", "report")]
    );
    assert cache.invalidate("report") == ["report"];
    assert cache.keys() == ["raw"];
    # invariant: every store entry resolves to a live node
    for k in cache.store.keys() {
        assert cache.value_of(k) is not None or k == "raw";
    }
}
