"""Base cache: a size-bounded mutable mapping (port of cachetools.Cache)."""
import collections;

glob _MARKER: object = object();


"""Mutable mapping to serve as a simple cache or cache base class.

Every value has a size (1 unless `getsizeof` is given); inserting beyond
`maxsize` evicts items via `popitem()`, which subclasses define.
"""
obj Cache(MutableMapping) {
    has maxsize: int;
    has getsizeof: Callable[[any], int] | None = None;
    has _data: dict[any, any] = {},
        _sizes: dict[any, int] = {},
        _currsize: int = 0;

    def postinit {
        if self.maxsize < 0 {
            raise ValueError("maxsize must be non-negative");
        }
    }

    has currsize: int {
        getter -> int { return self._currsize; }
    }

    def size_of(value: any) -> int {
        return self.getsizeof(value) if self.getsizeof is not None else 1;
    }

    def __getitem__(key: any) -> any {
        if key in self._data {
            return self._data[key];
        }
        return self.__missing__(key);
    }

    def __missing__(key: any) -> any {
        raise KeyError(key);
    }

    def __setitem__(key: any, value: any) -> None {
        size = self.size_of(value);
        if size < 0 {
            raise ValueError("value size must be non-negative");
        }
        if size > self.maxsize {
            raise ValueError("value too large");
        }
        diffsize = size;
        if key not in self._data {
            while self._currsize + diffsize > self.maxsize {
                self.popitem();
            }
        } else {
            diffsize = size - self._sizes[key];
            while self._currsize + diffsize > self.maxsize {
                self.popitem();
                if key not in self._data {
                    diffsize = size;
                }
            }
        }
        self._data[key] = value;
        self._sizes[key] = size;
        self._currsize += diffsize;
    }

    def __delitem__(key: any) -> None {
        size = self._sizes.pop(key);
        del self._data[key];
        self._currsize -= size;
    }

    def __contains__(key: any) -> bool {
        return key in self._data;
    }

    def __iter__ -> any {
        return iter(self._data);
    }

    def __len__ -> int {
        return len(self._data);
    }

    def __repr__ -> str {
        return f"{type(self).__name__}({self._data!r}, maxsize={self.maxsize!r}, currsize={self._currsize!r})";
    }

    # get/pop/setdefault go through `in` + [] so a subclass __missing__ is honoured
    def get(key: any, `default: any = None) -> any {
        return self[key] if key in self else `default;
    }

    def pop(key: any, `default: any = _MARKER) -> any {
        if key in self {
            value = self[key];
            del self[key];
            return value;
        }
        if `default is _MARKER {
            raise KeyError(key);
        }
        return `default;
    }

    def setdefault(key: any, `default: any = None) -> any {
        if key in self {
            return self[key];
        }
        self[key] = `default;
        return `default;
    }

    def popitem -> tuple[any, any] {
        raise KeyError(f"{type(self).__name__} is empty");
    }

    def clear -> None {
        self._data.clear();
        self._sizes.clear();
        self._currsize = 0;
    }
}
