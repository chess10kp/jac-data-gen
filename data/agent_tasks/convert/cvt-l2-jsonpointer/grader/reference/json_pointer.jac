"""Identify specific nodes in a JSON document (RFC 6901).

Port of python-json-pointer 3.2.0 (Stefan Kögl, Modified BSD License).
"""
import copy;
import re;

"""Sentinel meaning "no default given" for resolve()."""
glob NOTHING: object = object();

glob RE_ARRAY_INDEX: re.Pattern[str] = re.compile("0|[1-9][0-9]*$"),
     RE_INVALID_ESCAPE: re.Pattern[str] = re.compile("(~[^01]|~$)");

class JsonPointerException(Exception) {}

def escape(s: str) -> str {
    return s.replace("~", "~0").replace("/", "~1");
}

def unescape(s: str) -> str {
    return s.replace("~1", "/").replace("~0", "~");
}

"""Pairs of adjacent items: s -> (s0, s1), (s1, s2), ..."""
def pairwise(items: list[any]) -> list[tuple[any, any]] {
    return [(items[i], items[i + 1]) for i in range(len(items) - 1)];
}

"""Result of accessing element "-" of a list."""
obj EndOfList {
    has list_: Sequence[any];

    def __repr__ -> str {
        return f"{type(self).__name__}({self.list_!r})";
    }
}

"""A JSON Pointer that can reference parts of a JSON document."""
obj JsonPointer {
    has pointer: str;
    has parts: list[str] postinit;

    def postinit {
        invalid = RE_INVALID_ESCAPE.search(self.pointer);
        if invalid {
            raise JsonPointerException(f"Found invalid escape {invalid.group()}");
        }
        raw = self.pointer.split("/");
        if raw.pop(0) != "" {
            raise JsonPointerException("Location must start with /");
        }
        self.parts = [unescape(p) for p in raw];
    }

    """Constructs a pointer from a list of unescaped parts."""
    static def from_parts(parts: list[any]) -> JsonPointer {
        return JsonPointer("".join(["/" + escape(str(p)) for p in parts]));
    }

    """The next step converted to the right type for doc."""
    static def get_part(doc: any, part: str) -> any {
        if isinstance(doc, Mapping) {
            return part;
        }
        if isinstance(doc, str) {
            raise JsonPointerException(f"Cannot apply token '{part}' to non-container type {type(doc)}");
        }
        if isinstance(doc, Sequence) {
            if part == "-" {
                return part;
            }
            if not RE_ARRAY_INDEX.fullmatch(str(part)) {
                raise JsonPointerException(f"'{part}' is not a valid sequence index");
            }
            try {
                return int(part);
            } except ValueError as e {
                raise JsonPointerException(f"Invalid sequence index: {e}");
            }
        }
        if hasattr(doc, "__getitem__") {
            return part;
        }
        raise JsonPointerException(f"Document '{type(doc)}' does not support indexing, must be mapping/sequence or support __getitem__");
    }

    """Walk one step in doc and return the referenced part."""
    def walk(doc: any, part: str) -> any {
        key = JsonPointer.get_part(doc, part);
        if isinstance(doc, Sequence) {
            if key == "-" {
                return EndOfList(doc);
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

    """Resolve up to the last step: (sub-document, last key)."""
    def to_last(doc: any) -> tuple[any, any] {
        if not self.parts {
            return (doc, None);
        }
        for part in self.parts[:-1] {
            doc = self.walk(doc, part);
        }
        return (doc, JsonPointer.get_part(doc, self.parts[-1]));
    }

    """Resolve the pointer against doc; return default (if given) when missing."""
    def resolve(doc: any, `default: any = NOTHING) -> any {
        for part in self.parts {
            try {
                doc = self.walk(doc, part);
            } except JsonPointerException {
                if `default is NOTHING {
                    raise;
                }
                return `default;
            }
        }
        return doc;
    }

    def get(doc: any, `default: any = NOTHING) -> any {
        return self.resolve(doc, `default);
    }

    """Replace the target with value (on a deep copy unless inplace)."""
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
        }
        if isinstance(parent, list) and part == "-" {
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

    def get_parts -> list[str] {
        return self.parts;
    }

    """True if self starts with all the parts of ptr."""
    def contains(ptr: JsonPointer) -> bool {
        return self.parts[:len(ptr.parts)] == ptr.parts;
    }

    def __contains__(item: JsonPointer) -> bool {
        return self.contains(item);
    }

    """A new pointer with the suffix (pointer, string or list of parts) appended."""
    def join(suffix: any) -> JsonPointer {
        suffix_parts: any = suffix;
        if isinstance(suffix, JsonPointer) {
            suffix_parts = suffix.parts;
        } elif isinstance(suffix, str) {
            suffix_parts = JsonPointer(suffix).parts;
        }
        try {
            return JsonPointer.from_parts(list(self.parts) + list(suffix_parts));
        } except Exception {
            raise JsonPointerException("Invalid suffix");
        }
    }

    def __truediv__(suffix: any) -> JsonPointer {
        return self.join(suffix);
    }

    has path: str {
        getter -> str {
            return "".join(["/" + escape(p) for p in self.parts]);
        }
    }

    def __eq__(other: object) -> bool {
        if not isinstance(other, JsonPointer) {
            return False;
        }
        return self.parts == other.parts;
    }

    def __hash__ -> int {
        return hash(tuple(self.parts));
    }

    def __str__ -> str {
        return self.path;
    }

    def __repr__ -> str {
        return type(self).__name__ + "(" + repr(self.path) + ")";
    }
}

"""Resolve pointer against doc and return the referenced object."""
def resolve_pointer(doc: any, pointer: str, `default: any = NOTHING) -> any {
    return JsonPointer(pointer).resolve(doc, `default);
}

"""Set the value at pointer within doc (in place unless inplace=False)."""
def set_pointer(doc: any, pointer: str, value: any, inplace: bool = True) -> any {
    return JsonPointer(pointer).set(doc, value, inplace);
}
