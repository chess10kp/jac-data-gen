"""Event-driven cache invalidation over a model dependency graph.

Before-code synthesized from MaMpf-HD/mampf#863: today invalidation is a
brittle web of ``touch`` callbacks that only notify the immediate parent,
forcing long manual chains for deep dependencies. The refactor publishes
one change event and lets a central subscriber walk the dependency graph:
every downstream consumer is invalidated by an explicit BFS over adjacency
dicts, with a visited set so diamond fan-out does not loop.
"""
class DependencyGraph {
    def init(self: DependencyGraph)  -> Any {
        self.cache_key_of = {};
        self.depends_on = {};
        self.stale = `set();
    }
    def register(self: DependencyGraph, entity: Any, cache_key: Any)  -> Any {
        self.cache_key_of[entity] = cache_key;
        self.depends_on.setdefault(entity, `set());
    }
    """consumer reads producer: a change in producer invalidates consumer."""
    def add_dependency(self: DependencyGraph, consumer: Any, producer: Any)  -> Any {
        if (
            (consumer not in self.cache_key_of) or (producer not in self.cache_key_of)
        ) {
            raise KeyError("unknown entity");
        }
        if (consumer == producer) {
            raise ValueError("self dependency");
        }
        self.depends_on[consumer].add(producer);
    }
    """Producer -> consumers reading it, built once per publish."""
    def reverse_adjacency(self: DependencyGraph)  -> Any {
        rev: dict = {};
        for (consumer, producers) in list(self.depends_on.items()) {
            for p in list(producers) {
                rev.setdefault(p, []).append(consumer);
            }
        }
        return rev;
    }
    """One event walks the whole downstream closure.

        Explicit list-as-queue breadth-first frontier; the visited set is
        the cycle policy (dependency graphs can contain shared/diamond
        fans and imported cycles). Returns sorted newly-stale keys.
        """
    def publish_change(self: DependencyGraph, entity: Any)  -> Any {
        if (entity not in self.cache_key_of) {
            raise KeyError("unknown entity");
        }
        rev: dict = dict(self.reverse_adjacency());
        frontier = [entity];
        visited = {entity};
        touched = [];
        while frontier {
            nxt = [];
            for cur in frontier {
                for consumer in list(rev.get(cur, [])) {
                    if (consumer in visited) {
                        continue;
                    }
                    visited.add(consumer);
                    nxt.append(consumer);
                    touched.append(consumer);
                }
            }
            frontier = nxt;
        }
        keys = [];
        for c in touched {
            keys.append(self.cache_key_of[c]);
        }
        keys = sorted(keys);
        self.stale.update(keys);
        return keys;
    }

    """Bounded-depth variant: stop expanding past ``depth_cap`` hops.

        Kept as domain semantics -- some callers must not sweep beyond a
        known nesting budget even if more dependents exist.
        """
    def invalidate_all_upstream_of(
        self: DependencyGraph, entity: Any, depth_cap: Any
    ) -> Any {
        if (entity not in self.cache_key_of) {
            raise KeyError("unknown entity");
        }
        rev: dict = dict(self.reverse_adjacency());
        frontier = [entity];
        visited = {entity};
        touched = [];
        depth = 0;
        while (frontier and (depth < depth_cap)) {
            nxt = [];
            for cur in frontier {
                for consumer in list(rev.get(cur, [])) {
                    if (consumer in visited) {
                        continue;
                    }
                    visited.add(consumer);
                    nxt.append(consumer);
                    touched.append(consumer);
                }
            }
            frontier = nxt;
            depth += 1;
        }
        keys = [];
        for c in touched {
            keys.append(self.cache_key_of[c]);
        }
        keys = sorted(keys);
        self.stale.update(keys);
        return keys;
    }

    def is_stale(self: DependencyGraph, entity: Any)  -> Any {
        return (self.cache_key_of[entity] in self.stale);
    }
    def mark_fresh(self: DependencyGraph, entity: Any)  -> Any {
        self.stale.discard(self.cache_key_of[entity]);
    }
}

