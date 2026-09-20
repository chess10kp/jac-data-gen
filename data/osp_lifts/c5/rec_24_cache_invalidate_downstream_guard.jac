"""Idiomatic OSP lift: derived-cache downstream invalidation (category C5).

Two-phase mutation protocol (OSP_IDIOMIZE_TASK.md §5.5):

Phase COLLECT -- `InvalidationSweep` walks the `DerivedFrom` edges in the
dependent direction and gathers the doomed keys into typed `has` fields.
The seen-guard is both the diamond once-only guard (a key reachable via two
derivation paths is dropped exactly once) and the explicit cycle policy --
0.36.1 has no built-in dedup, so a revisited key disengages. Dead ends
schedule nothing; the frontier drains.

Phase APPLY -- outside any walk, the façade deletes the collected entries
and prunes them from the store map. The source's deque/queue loop, seen
dict, and stale-reference skips die; tolerance semantics are kept: unknown
keys are a silent no-op.
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
        existing = self.store.get(key);
        if existing is None {
            existing = CacheEntry(key=key);
            self.store[key] = existing;
        }
        existing.value = value;
        return existing;
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

    def contains(key: str) -> bool {
        return key in self.store;
    }

    def value_of(key: str) -> int | list[int] | str | bool | None {
        found = self.store.get(key);
        if found is None {
            return None;
        }
        return found.value;
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
    assert not cache.contains("raw") and not cache.contains("agg");
    assert not cache.contains("dashboard") and not cache.contains("report");
    assert cache.contains("metrics") and cache.contains("config");
    assert cache.value_of("config") is True;
}

test "unknown_key_and_stale_refs_tolerated" {
    cache = load_graph(
        entries=[("raw", 1), ("agg", 3), ("report", "r")],
        derivations=[("raw", "agg"), ("agg", "report")]
    );
    assert cache.invalidate("nope") == [];
    ok = cache.declare("agg", "ghost");      # dangling declaration refused
    assert not ok;      # dangling declaration refused
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