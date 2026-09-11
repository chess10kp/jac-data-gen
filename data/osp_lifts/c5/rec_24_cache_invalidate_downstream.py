"""In-memory derived-cache registry with downstream invalidation.

Cache entries may be derived from other entries; ``dependents`` records
which keys must be dropped when a source entry changes (dependency
direction: entry -> things derived FROM it). ``invalidate`` performs a
breadth-first sweep over the dependent closure -- a diamond dependency
reaches a key twice but it must be dropped exactly once -- deletes every
collected entry from the store and returns the keys it removed, sorted.
Unknown keys and stale dependent references are tolerated silently.
"""

from collections import deque


class CacheEntry:
    def __init__(self, key):
        self.key = key
        self.value = None
        self.dependents = []     # keys derived from this entry


class DerivedCache:
    def __init__(self):
        self.store = {}          # key -> CacheEntry

    def put(self, key, value):
        entry = self.store.get(key)
        if entry is None:
            entry = CacheEntry(key)
            self.store[key] = entry
        entry.value = value
        return entry

    def declare(self, source_key, dependent_key):
        """Register *dependent_key* as derived from *source_key*."""
        if source_key not in self.store or dependent_key not in self.store:
            return False         # tolerate dangling declarations
        self.store[source_key].dependents.append(dependent_key)
        return True

    def invalidate(self, key):
        """Drop *key* and every transitive dependent from the store.

        Returns the sorted list of removed keys. Unknown keys are a no-op;
        stale dependent ids encountered mid-sweep are skipped.
        """
        if key not in self.store:
            return []
        frontier = deque([key])
        seen = {key}
        doomed = []
        while frontier:
            current = frontier.popleft()
            doomed.append(current)
            for dep in self.store[current].dependents:
                if dep in seen:
                    continue     # diamond / cycle policy: drop once only
                if dep not in self.store:
                    continue     # stale reference
                seen.add(dep)
                frontier.append(dep)
        for k in doomed:
            del self.store[k]
        return sorted(doomed)

    def has(self, key):
        return key in self.store

    def value_of(self, key):
        entry = self.store.get(key)
        return entry.value if entry else None

    def keys(self):
        return sorted(self.store.keys())
