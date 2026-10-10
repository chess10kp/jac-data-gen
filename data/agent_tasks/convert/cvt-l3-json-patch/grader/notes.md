# cvt-l3-json-patch
Sources: jsonpointer 3.2.0 + jsonpatch 1.34 (both Modified BSD, Stefan Kögl), from PyPI sdists.
Starter: trimmed jsonpatch.py (no diff generation) + full jsonpointer.py + trimmed upstream tests.
Hidden tests: 13 cases ported from upstream unit tests (spec examples, round-trip, comparison/join,
set, add/remove/replace/move/copy/test, whole-document ops, patch immutability, invalid input,
conflicts, no string indexing). Exception classes matter (JsonPatchConflict vs JsonPointerException).
Negatives: insert-at-end rejected, add shares patch value (no deepcopy), move-into-child allowed,
test op leaks pointer error, unescape order swapped, leading-zero array index accepted.
Jac quirks hit while porting: `default` and `obj` are keywords (backtick-escape / rename);
`Mapping`/`MutableMapping` are ambient (importing them is E1125); a `postinit` field must come
after the constructor fields (E2004); `has x: T postinit;` (no `by`).
