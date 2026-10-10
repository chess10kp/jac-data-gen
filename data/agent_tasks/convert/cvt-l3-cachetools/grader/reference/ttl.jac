"""LRU cache whose items expire `ttl` time units after being set (port of cachetools.TTLCache)."""
import collections;
import time;
import from basecache { Cache }

obj TTLCache(Cache) {
    has ttl: float = 600.0;
    has timer: Callable[[], float] = time.monotonic;
    # key -> expiry time, ordered least- to most-recently used
    has _expires: collections.OrderedDict[any, float] = collections.OrderedDict();

    def __contains__(key: any) -> bool {
        return key in self._expires and self.timer() < self._expires[key];
    }

    def __getitem__(key: any) -> any {
        if key in self._expires {
            self._expires.move_to_end(key);
            if not (self.timer() < self._expires[key]) {
                return self.__missing__(key);
            }
        }
        return super.__getitem__(key);
    }

    def __setitem__(key: any, value: any) -> None {
        now = self.timer();
        self.expire(now);
        super.__setitem__(key, value);
        self._expires[key] = now + self.ttl;
        self._expires.move_to_end(key);
    }

    def __delitem__(key: any) -> None {
        super.__delitem__(key);
        expires = self._expires.pop(key);
        if not (self.timer() < expires) {
            raise KeyError(key);
        }
    }

    def __iter__ -> any {
        now = self.timer();
        return iter([k for (k, t) in self._expires.items() if now < t]);
    }

    def __len__ -> int {
        self.expire(self.timer());
        return super.__len__();
    }

    has currsize: int {
        getter -> int {
            self.expire(self.timer());
            return self._currsize;
        }
    }

    """Remove expired items; return the list of expired (key, value) pairs."""
    def expire(at: float | None = None) -> list[tuple[any, any]] {
        now = self.timer() if at is None else at;
        gone: list[tuple[any, any]] = [];
        for (key, t) in list(self._expires.items()) {
            if now < t {
                continue;
            }
            gone.append((key, self._data[key]));
            super.__delitem__(key);
            del self._expires[key];
        }
        return gone;
    }

    """Remove and return the least recently used item that has not expired."""
    def popitem -> tuple[any, any] {
        self.expire(self.timer());
        if len(self._expires) == 0 {
            raise KeyError(f"{type(self).__name__} is empty");
        }
        key = next(iter(self._expires));
        return (key, self.pop(key));
    }

    def clear -> None {
        super.clear();
        self._expires.clear();
    }
}
