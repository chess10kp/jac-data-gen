# Vendored grammar sources

`parser.c`, `scanner.c`, and `src/tree_sitter/*.h` are the committed build
outputs of [jaseci-labs/tree-sitter-jac](https://github.com/jaseci-labs/tree-sitter-jac),
vendored so this package builds standalone (see `../setup.py`).

Refresh after grammar changes:

```bash
cp ~/repos/tree-sitter-jac/src/{parser.c,scanner.c} python/vendor/tree-sitter-jac/src/
cp ~/repos/tree-sitter-jac/src/tree_sitter/{alloc.h,array.h,parser.h} python/vendor/tree-sitter-jac/src/tree_sitter/
```
