"""In-memory derived-cache registry with downstream invalidation.

Cache entries may be derived from other entries; ``dependents`` records
which keys must be dropped when a source entry changes (dependency
direction: entry -> things derived FROM it). ``invalidate`` performs a
breadth-first sweep over the dependent closure -- a diamond dependency
reaches a key twice but it must be dropped exactly once -- deletes every
collected entry from the store and returns the keys it removed, sorted.
Unknown keys and stale dependent references are tolerated silently.
"""
import from collections { deque }
class CacheEntry {
    has key: str;
    has value: object = None;
    def init(self: CacheEntry, key: str) -> object {
        self.key = key;
        self.value = None;
        self.dependents = [];
    }
}
class DerivedCache {
    has store: dict[str, CacheEntry];
    def init(self: DerivedCache) -> object {
        self.store = {};
    }
    def put(self: DerivedCache, key: str, value: object) -> object {
        `entry = self.store.get(key);
        if (`entry is None) {
            `entry = CacheEntry(key);
            self.store[key] = `entry;
        }
        `entry.value = value;
        return `entry;
    }
    def declare(self: DerivedCache, source_key: str, dependent_key: str) -> object {
        if ((source_key not in self.store) or (dependent_key not in self.store)) {
            return False;
        }
        self.store[source_key].dependents.append(dependent_key);
        return True;
    }
    def invalidate(self: DerivedCache, key: str) -> object {
        if (key not in self.store) {
            return [];
        }
        frontier = deque([key]);
        seen = {key};
        doomed = [];
        while frontier {
            current = frontier.popleft();
            doomed.append(current);
            for dep in self.store[current].dependents {
                if (dep in seen) {
                    continue;
                }
                if (dep not in self.store) {
                    continue;
                }
                seen.add(dep);
                frontier.append(dep);
            }
        }
        for k in doomed {
            delete(self.store[k],);
        }
        return sorted(doomed);
    }

    def `has(self: DerivedCache, key: Any) -> object {
        return (key in self.store);
    }
    def value_of(self: DerivedCache, key: str) -> object {
        `entry = self.store.get(key);
        return `entry.value if `entry else None;
    }
    def keys(self: DerivedCache) -> object {
        return sorted(self.store.keys());
    }
}

