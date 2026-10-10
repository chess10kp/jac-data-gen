I want to stop depending on the `jsonpointer` / `jsonpatch` pip packages in our Jac services and have our own Jac version. I copied the upstream sources into `python/` (`jsonpointer.py`, and `jsonpatch.py` with the diff/`make_patch` part already cut out since we don't need it) along with their unit tests.

Please port them to two Jac modules in the project root:

**`pointer.jac`** (RFC 6901)
- `JsonPointerException`, `EndOfList`, and `escape(s)` / `unescape(s)`
- `JsonPointer` — constructed from a pointer string (`JsonPointer("/a/b")`), with `.parts`, `get_parts()`, `resolve(doc, default)`, `get(...)`, `set(doc, value, inplace=True)`, `to_last(doc)`, `walk(doc, part)`, `contains(other)` (plus `in`), `join(suffix)`, a static `from_parts(parts)`, equality/hash, and `str()` giving the escaped path
- module functions `resolve_pointer(doc, pointer, default)` and `set_pointer(doc, pointer, value, inplace=True)`

**`patch.jac`** (RFC 6902, apply side only), importing from `pointer.jac`
- the exceptions `JsonPatchException`, `InvalidJsonPatch`, `JsonPatchConflict`, `JsonPatchTestFailed` (the last one should also be an `AssertionError`, like upstream)
- `JsonPatch(patch=[...])` with `apply(doc, in_place=False)`, a static `from_string(json_text)`, `to_string()`, and truthiness
- `apply_patch(doc, patch, in_place=False)` where `patch` is a list of operations or a JSON string
- all six ops (add/remove/replace/move/copy/test) with the same error behaviour as the Python code — which exception gets raised matters to us, and applying a patch must never mutate the patch itself or share values with it.

Use Jac `obj`s for the classes (the operations can be a small obj hierarchy) and don't import the Python packages. `jac check` should be clean on both files.
