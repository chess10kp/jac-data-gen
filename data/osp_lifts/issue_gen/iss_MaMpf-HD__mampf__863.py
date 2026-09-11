"""Event-driven cache invalidation over a model dependency graph.

Before-code synthesized from MaMpf-HD/mampf#863: today invalidation is a
brittle web of ``touch`` callbacks that only notify the immediate parent,
forcing long manual chains for deep dependencies. The refactor publishes
one change event and lets a central subscriber walk the dependency graph:
every downstream consumer is invalidated by an explicit BFS over adjacency
dicts, with a visited set so diamond fan-out does not loop.
"""


class DependencyGraph:
    def __init__(self):
        self.cache_key_of = {}   # entity -> its own cache key
        self.depends_on = {}     # consumer -> set of producers it reads
        self.stale = set()

    def register(self, entity, cache_key):
        self.cache_key_of[entity] = cache_key
        self.depends_on.setdefault(entity, set())

    def add_dependency(self, consumer, producer):
        """consumer reads producer: a change in producer invalidates consumer."""
        if consumer not in self.cache_key_of or producer not in self.cache_key_of:
            raise KeyError("unknown entity")
        if consumer == producer:
            raise ValueError("self dependency")
        self.depends_on[consumer].add(producer)

    def reverse_adjacency(self):
        """Producer -> consumers reading it, built once per publish."""
        rev = {}
        for consumer, producers in self.depends_on.items():
            for p in producers:
                rev.setdefault(p, []).append(consumer)
        return rev

    def publish_change(self, entity):
        """One event walks the whole downstream closure.

        Explicit list-as-queue breadth-first frontier; the visited set is
        the cycle policy (dependency graphs can contain shared/diamond
        fans and imported cycles). Returns sorted newly-stale keys.
        """
        if entity not in self.cache_key_of:
            raise KeyError("unknown entity")
        rev = self.reverse_adjacency()
        frontier = [entity]
        visited = {entity}
        touched = []
        while frontier:
            nxt = []
            for cur in frontier:
                for consumer in rev.get(cur, []):
                    if consumer in visited:
                        continue
                    visited.add(consumer)
                    nxt.append(consumer)
                    touched.append(consumer)
            frontier = nxt
        keys = sorted(self.cache_key_of[c] for c in touched)
        self.stale.update(keys)
        return keys

    def invalidate_all_upstream_of(self, entity, depth_cap):
        """Bounded-depth variant: stop expanding past ``depth_cap`` hops.

        Kept as domain semantics -- some callers must not sweep beyond a
        known nesting budget even if more dependents exist.
        """
        if entity not in self.cache_key_of:
            raise KeyError("unknown entity")
        rev = self.reverse_adjacency()
        frontier = [entity]
        visited = {entity}
        touched = []
        depth = 0
        while frontier and depth < depth_cap:
            nxt = []
            for cur in frontier:
                for consumer in rev.get(cur, []):
                    if consumer in visited:
                        continue
                    visited.add(consumer)
                    nxt.append(consumer)
                    touched.append(consumer)
            frontier = nxt
            depth += 1
        keys = sorted(self.cache_key_of[c] for c in touched)
        self.stale.update(keys)
        return keys

    def is_stale(self, entity):
        return self.cache_key_of[entity] in self.stale

    def mark_fresh(self, entity):
        self.stale.discard(self.cache_key_of[entity])
