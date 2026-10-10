"""Apply JSON Patches (RFC 6902).

Jac port of python-json-patch 1.34 (jsonpatch.py), apply side only.
"""
import copy;
import json;
import from pointer { JsonPointer, JsonPointerException }

obj JsonPatchException(Exception) {}

"""Raised if an invalid JSON Patch is created."""
obj InvalidJsonPatch(JsonPatchException) {}

"""Raised if a patch cannot be applied because of a conflict (missing key, index out of range, ...)."""
obj JsonPatchConflict(JsonPatchException) {}

"""A `test` operation failed."""
obj JsonPatchTestFailed(JsonPatchException, AssertionError) {}

"""Convert duplicate JSON object keys into lists of values."""
def multidict(ordered_pairs: list[tuple[str, any]]) -> dict[str, any] {
    grouped: dict[str, list[any]] = {};
    for (key, value) in ordered_pairs {
        grouped.setdefault(key, []).append(value);
    }
    return {k: (v[0] if len(v) == 1 else v) for (k, v) in grouped.items()};
}

"""Like JsonPointer.to_last, but never indexes into strings."""
def _to_last(ptr: JsonPointer, doc: any) -> tuple[any, any] {
    (subobj, part) = ptr.to_last(doc);
    if part is not None and isinstance(subobj, str) {
        raise JsonPointerException(f"Cannot apply token '{part}' to non-container type {type(subobj)}");
    }
    return (subobj, part);
}

def _pointer(location: any) -> JsonPointer {
    if isinstance(location, JsonPointer) {
        return location;
    }
    if not isinstance(location, str) {
        raise InvalidJsonPatch("Invalid 'path'");
    }
    return JsonPointer(location);
}

"""A single operation inside a JSON Patch."""
obj PatchOperation {
    has operation: dict[str, any];
    has location: str postinit;
    has ptr: JsonPointer postinit;

    def postinit {
        if "path" not in self.operation {
            raise InvalidJsonPatch("Operation must have a 'path' member");
        }
        self.ptr = _pointer(self.operation["path"]);
        self.location = self.ptr.path();
    }

    def value -> any {
        if "value" not in self.operation {
            raise InvalidJsonPatch("The operation does not contain a 'value' member");
        }
        return self.operation["value"];
    }

    def from_pointer -> JsonPointer {
        if "from" not in self.operation {
            raise InvalidJsonPatch("The operation does not contain a 'from' member");
        }
        return _pointer(self.operation["from"]);
    }

    def apply(doc: any) -> any {
        raise NotImplementedError("should implement the patch operation.");
    }

    def __eq__(other: any) -> bool {
        return isinstance(other, PatchOperation) and self.operation == other.operation;
    }
}

"""Removes an object property or an array element."""
obj RemoveOperation(PatchOperation) {
    def apply(doc: any) -> any {
        (subobj, part) = _to_last(self.ptr, doc);
        if isinstance(subobj, list) and not isinstance(part, int) {
            raise JsonPointerException(f"invalid array index '{part}'");
        }
        try {
            del subobj[part];
        } except (KeyError, IndexError) {
            raise JsonPatchConflict(f"can't remove a non-existent object '{part}'");
        }
        return doc;
    }
}

"""Adds an object property or an array element."""
obj AddOperation(PatchOperation) {
    def apply(doc: any) -> any {
        # insert a copy so the document never shares mutable values with the patch
        return self.add(doc, copy.deepcopy(self.value()));
    }

    def add(doc: any, value: any) -> any {
        (subobj, part) = _to_last(self.ptr, doc);
        if part is None {
            return value;  # replacing the whole document
        }
        if isinstance(subobj, list) {
            if part == "-" {
                subobj.append(value);
            } elif part > len(subobj) or part < 0 {
                raise JsonPatchConflict("can't insert outside of list");
            } else {
                subobj.insert(part, value);
            }
        } elif isinstance(subobj, MutableMapping) {
            subobj[part] = value;
        } else {
            raise JsonPatchConflict(f"unable to fully resolve json pointer {self.location}, part {part}");
        }
        return doc;
    }
}

"""Replaces an object property or an array element by a new value."""
obj ReplaceOperation(PatchOperation) {
    def apply(doc: any) -> any {
        value = copy.deepcopy(self.value());
        (subobj, part) = _to_last(self.ptr, doc);
        if part is None {
            return value;
        }
        if part == "-" {
            raise InvalidJsonPatch("'path' with '-' can't be applied to 'replace' operation");
        }
        if isinstance(subobj, list) {
            if part >= len(subobj) or part < 0 {
                raise JsonPatchConflict("can't replace outside of list");
            }
        } elif isinstance(subobj, MutableMapping) {
            if part not in subobj {
                raise JsonPatchConflict(f"can't replace a non-existent object '{part}'");
            }
        } else {
            raise JsonPatchConflict(f"unable to fully resolve json pointer {self.location}, part {part}");
        }
        subobj[part] = value;
        return doc;
    }
}

"""Moves an object property or an array element to a new location."""
obj MoveOperation(PatchOperation) {
    def apply(doc: any) -> any {
        src = self.from_pointer();
        (subobj, part) = _to_last(src, doc);
        value: any = None;
        try {
            value = subobj[part];
        } except (KeyError, IndexError) as ex {
            raise JsonPatchConflict(str(ex));
        }
        if self.ptr == src {
            return doc;
        }
        if isinstance(subobj, MutableMapping) and self.ptr.contains(src) {
            raise JsonPatchConflict("Cannot move values into their own children");
        }
        doc = RemoveOperation(operation={"op": "remove", "path": src}).apply(doc);
        # detached from its old location already, so no copy needed
        return AddOperation(operation={"op": "add", "path": self.location}).add(doc, value);
    }
}

"""Tests the value at the specified location."""
obj TestOperation(PatchOperation) {
    def apply(doc: any) -> any {
        found: any = None;
        try {
            (subobj, part) = _to_last(self.ptr, doc);
            found = subobj if part is None else self.ptr.walk(subobj, part);
        } except JsonPointerException as ex {
            raise JsonPatchTestFailed(str(ex));
        }
        expected = self.value();
        if found != expected {
            raise JsonPatchTestFailed(f"{found} ({type(found)}) is not equal to tested value {expected} ({type(expected)})");
        }
        return doc;
    }
}

"""Copies an object property or an array element to a new location."""
obj CopyOperation(PatchOperation) {
    def apply(doc: any) -> any {
        src = self.from_pointer();
        (subobj, part) = _to_last(src, doc);
        value: any = None;
        try {
            value = copy.deepcopy(subobj if part is None else subobj[part]);
        } except (KeyError, IndexError) as ex {
            raise JsonPatchConflict(str(ex));
        }
        return AddOperation(operation={"op": "add", "path": self.location}).add(doc, value);
    }
}

"""Build the operation object for one patch entry."""
def make_operation(operation: dict[str, any]) -> PatchOperation {
    if "op" not in operation {
        raise InvalidJsonPatch("Operation does not contain 'op' member");
    }
    op = operation["op"];
    if not isinstance(op, str) {
        raise InvalidJsonPatch("Operation's op must be a string");
    }
    match op {
        case "remove": return RemoveOperation(operation=operation);
        case "add": return AddOperation(operation=operation);
        case "replace": return ReplaceOperation(operation=operation);
        case "move": return MoveOperation(operation=operation);
        case "test": return TestOperation(operation=operation);
        case "copy": return CopyOperation(operation=operation);
        case _: raise InvalidJsonPatch(f"Unknown operation {op!r}");
    }
}

"""A JSON Patch is a list of patch operations."""
obj JsonPatch {
    has patch: list[dict[str, any]];

    def postinit {
        # validate the structure up front: a bare dict / list of strings is rejected
        if not isinstance(self.patch, list) {
            raise InvalidJsonPatch("Document is expected to be sequence of operations");
        }
        for op in self.patch {
            if not isinstance(op, dict) {
                raise InvalidJsonPatch("Document is expected to be sequence of operations, got a sequence of strings.");
            }
            make_operation(op);
        }
    }

    static def from_string(patch_str: str) -> JsonPatch {
        return JsonPatch(patch=json.loads(patch_str, object_pairs_hook=multidict));
    }

    def to_string -> str {
        return json.dumps(self.patch);
    }

    def operations -> list[PatchOperation] {
        return [make_operation(op) for op in self.patch];
    }

    """Apply the patch to `doc` (to a deep copy unless in_place)."""
    def apply(doc: any, in_place: bool = False) -> any {
        if not in_place {
            doc = copy.deepcopy(doc);
        }
        for operation in self.operations() {
            doc = operation.apply(doc);
        }
        return doc;
    }

    def __bool__ -> bool {
        return len(self.patch) > 0;
    }

    def __len__ -> int {
        return len(self.patch);
    }

    def __eq__(other: any) -> bool {
        return isinstance(other, JsonPatch) and self.operations() == other.operations();
    }

    def __str__ -> str {
        return self.to_string();
    }
}

"""Apply a patch (list of operations or JSON string) to `doc`."""
def apply_patch(doc: any, patch: any, in_place: bool = False) -> any {
    p = JsonPatch.from_string(patch) if isinstance(patch, str) else JsonPatch(patch=patch);
    return p.apply(doc, in_place);
}
