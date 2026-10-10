hey — I vendored the `jsonpointer` library into `python/jsonpointer.py` (upstream tests are in `python/test_jsonpointer.py`). We want a native Jac version so we can drop the dependency. Please write `json_pointer.jac` with:

- `JsonPointer` as an `obj` constructed from the pointer string (`JsonPointer("/foo/0")`), keeping `parts`, `path`, `resolve`/`get` (with an optional default), `set(doc, value, inplace=True)`, `to_last`, `walk`, `get_part`, `get_parts`, `contains` / `in`, `join` / the `/` operator, `from_parts`, plus equality, hashing, `str()` and `repr()` exactly like the Python class
- `EndOfList` (returned for the `-` index) and `JsonPointerException`
- the module functions `resolve_pointer`, `set_pointer`, `escape`, `unescape` and `pairwise`

Error cases should raise `JsonPointerException` the same way the original does (bad escapes, missing leading slash, invalid/leading-zero/out-of-range indexes, indexing into strings, setting the root in place...). The command-line script and the `VERBOSE_EXCEPTIONS` toggle aren't needed — just always use the verbose "member 'x' not found in {doc}" message. It should also keep working on any object that supports `__getitem__`, not only dicts and lists.

Don't import the Python module; make sure `jac check` passes.
