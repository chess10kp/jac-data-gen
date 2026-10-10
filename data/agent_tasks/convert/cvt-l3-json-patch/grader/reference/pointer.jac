"""Identify specific nodes in a JSON document (RFC 6901).

Jac port of python-json-pointer 3.2.0 (jsonpointer.py).
"""
import copy;
import re;

"""Sentinel meaning "no default given" for resolve()."""
glob _NOTHING: object = object();

"""Array indices must not contain leading zeros, signs, spaces, decimals, etc."""
glob _RE_ARRAY_INDEX: re.Pattern[str] = re.compile("0|[1-9][0-9]*$"),
     _RE_INVALID_ESCAPE: re.Pattern[str] = re.compile("(~[^01]|~$)");

obj JsonPointerException(Exception) {}

"""Result of accessing element "-" of a list."""
obj EndOfList {
    has list_: list[any];
}

def escape(s: str) -> str {
    return s.replace("~", "~0").replace("/", "~1");
}

def unescape(s: str) -> str {
    return s.replace("~1", "/").replace("~0", "~");
}

"""A JSON Pointer that can reference parts of a JSON document."""
obj JsonPointer {
    has pointer: str;
    has parts: list[str] postinit;

    def postinit {
        bad = _RE_INVALID_ESCAPE.search(self.pointer);
        if bad {
            raise JsonPointerException(f"Found invalid escape {bad.group()}");
        }
        raw = self.pointer.split("/");
        if raw.pop(0) != "" {
            raise JsonPointerException("Location must start with /");
        }
        self.parts = [unescape(p) for p in raw];
    }

    """Construct a pointer from a list of (unescaped) parts."""
    static def from_parts(parts: list[any]) -> JsonPointer {
        return JsonPointer("".join(["/" + escape(str(p)) for p in parts]));
    }

    """String form of the pointer, re-escaped."""
    def path -> str {
        return "".join(["/" + escape(p) for p in self.parts]);
    }

    def get_parts -> list[str] {
        return self.parts;
    }

    """Return the next step `part` converted to the right type for `doc`."""
    static def get_part(doc: any, part: str) -> any {
        if isinstance(doc, Mapping) {
            return part;
        }
        if isinstance(doc, str) {
            raise JsonPointerException(f"Cannot apply token '{part}' to non-container type {type(doc)}");
        }
        if isinstance(doc, list) {
            if part == "-" {
                return part;
            }
            if not _RE_ARRAY_INDEX.fullmatch(str(part)) {
                raise JsonPointerException(f"'{part}' is not a valid sequence index");
            }
            return int(part);
        }
        if hasattr(doc, "__getitem__") {
            return part;
        }
        raise JsonPointerException(f"Document '{type(doc)}' does not support indexing, must be mapping/sequence or support __getitem__");
    }

    """Walk one step into `doc` and return the referenced part."""
    def walk(doc: any, part: str) -> any {
        key = JsonPointer.get_part(doc, part);
        if isinstance(doc, list) {
            if key == "-" {
                return EndOfList(list_=doc);
            }
            try {
                return doc[key];
            } except IndexError {
                raise JsonPointerException(f"index '{key}' is out of bounds");
            }
        }
        try {
            return doc[key];
        } except KeyError {
            raise JsonPointerException(f"member '{key}' not found in {doc}");
        }
    }

    """Resolve until the last step; returns (sub-document, last step)."""
    def to_last(doc: any) -> tuple[any, any] {
        if not self.parts {
            return (doc, None);
        }
        for part in self.parts[:-1] {
            doc = self.walk(doc, part);
        }
        return (doc, JsonPointer.get_part(doc, self.parts[-1]));
    }

    """Resolve the pointer against `doc`; return `default` (if given) when missing."""
    def resolve(doc: any, `default: any = _NOTHING) -> any {
        for part in self.parts {
            try {
                doc = self.walk(doc, part);
            } except JsonPointerException as e {
                if `default is _NOTHING {
                    raise e;
                }
                return `default;
            }
        }
        return doc;
    }

    def get(doc: any, `default: any = _NOTHING) -> any {
        return self.resolve(doc, `default);
    }

    """Replace the target of the pointer inside `doc` with `value`."""
    def set(doc: any, value: any, inplace: bool = True) -> any {
        if len(self.parts) == 0 {
            if inplace {
                raise JsonPointerException("Cannot set root in place");
            }
            return value;
        }
        if not inplace {
            doc = copy.deepcopy(doc);
        }
        (parent, part) = self.to_last(doc);
        if isinstance(parent, str) {
            raise JsonPointerException("Cannot set value in a string");
        } elif isinstance(parent, list) and part == "-" {
            parent.append(value);
        } else {
            try {
                parent[part] = value;
            } except (TypeError, IndexError) as e {
                raise JsonPointerException(f"Invalid assignment target: {e}");
            }
        }
        return doc;
    }

    """True if this pointer is a prefix of (or equal to) `ptr`... i.e. self contains ptr."""
    def contains(ptr: JsonPointer) -> bool {
        return self.parts[:len(ptr.parts)] == ptr.parts;
    }

    """New pointer with `suffix` (pointer, pointer string or parts list) appended."""
    def join(suffix: any) -> JsonPointer {
        try {
            extra: list[any] = [];
            if isinstance(suffix, JsonPointer) {
                extra = suffix.parts;
            } elif isinstance(suffix, str) {
                extra = JsonPointer(suffix).parts;
            } else {
                extra = list(suffix);
            }
            return JsonPointer.from_parts(self.parts + extra);
        } except Exception {
            raise JsonPointerException("Invalid suffix");
        }
    }

    def __contains__(item: JsonPointer) -> bool {
        return self.contains(item);
    }

    def __eq__(other: any) -> bool {
        return isinstance(other, JsonPointer) and self.parts == other.parts;
    }

    def __hash__ -> int {
        return hash(tuple(self.parts));
    }

    def __str__ -> str {
        return self.path();
    }
}

"""Resolve `pointer` against `doc` and return the referenced object."""
def resolve_pointer(doc: any, pointer: str, `default: any = _NOTHING) -> any {
    return JsonPointer(pointer).resolve(doc, `default);
}

"""Set the target of `pointer` within `doc` to `value`."""
def set_pointer(doc: any, pointer: str, value: any, inplace: bool = True) -> any {
    return JsonPointer(pointer).set(doc, value, inplace);
}
