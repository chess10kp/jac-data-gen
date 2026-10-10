"""Eviction policies on top of Cache: FIFO, LRU and LFU (port of cachetools)."""
import collections;
import from basecache { Cache }

"""First In First Out: evicts the item inserted first."""
obj FIFOCache(Cache) {
    has _order: collections.OrderedDict[any, None] = collections.OrderedDict();

    def __setitem__(key: any, value: any) -> None {
        super.__setitem__(key, value);
        if key in self._order {
            self._order.move_to_end(key);
        } else {
            self._order[key] = None;
        }
    }

    def __delitem__(key: any) -> None {
        super.__delitem__(key);
        del self._order[key];
    }

    """Remove and return the (key, value) pair inserted first."""
    def popitem -> tuple[any, any] {
        if len(self._order) == 0 {
            raise KeyError(f"{type(self).__name__} is empty");
        }
        key = next(iter(self._order));
        return (key, self.pop(key));
    }

    def clear -> None {
        super.clear();
        self._order.clear();
    }
}

"""Least Recently Used: reads and writes refresh an item."""
obj LRUCache(Cache) {
    has _order: collections.OrderedDict[any, None] = collections.OrderedDict();

    def _touch(key: any) -> None {
        if key in self._order {
            self._order.move_to_end(key);
        } else {
            self._order[key] = None;
        }
    }

    def __getitem__(key: any) -> any {
        value = super.__getitem__(key);
        if key in self {  # __missing__ may not store the item
            self._touch(key);
        }
        return value;
    }

    def __setitem__(key: any, value: any) -> None {
        super.__setitem__(key, value);
        self._touch(key);
    }

    def __delitem__(key: any) -> None {
        super.__delitem__(key);
        del self._order[key];
    }

    """Remove and return the (key, value) pair least recently used."""
    def popitem -> tuple[any, any] {
        if len(self._order) == 0 {
            raise KeyError(f"{type(self).__name__} is empty");
        }
        key = next(iter(self._order));
        return (key, self.pop(key));
    }

    def clear -> None {
        super.clear();
        self._order.clear();
    }
}

"""Least Frequently Used: evicts the item read/written the fewest times.

Ties are broken by insertion order (upstream evicts an arbitrary one).
"""
obj LFUCache(Cache) {
    has _counts: dict[any, int] = {};

    def __getitem__(key: any) -> any {
        value = super.__getitem__(key);
        if key in self {
            self._counts[key] += 1;
        }
        return value;
    }

    def __setitem__(key: any, value: any) -> None {
        super.__setitem__(key, value);
        self._counts[key] = self._counts.get(key, 0) + 1;
    }

    def __delitem__(key: any) -> None {
        super.__delitem__(key);
        del self._counts[key];
    }

    """Remove and return the (key, value) pair least frequently used."""
    def popitem -> tuple[any, any] {
        if len(self._counts) == 0 {
            raise KeyError(f"{type(self).__name__} is empty");
        }
        key = min(self._counts, key=lambda (k: any) -> int { return self._counts[k]; });
        return (key, self.pop(key));
    }

    def clear -> None {
        super.clear();
        self._counts.clear();
    }
}
