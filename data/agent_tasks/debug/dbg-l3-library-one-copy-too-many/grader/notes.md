# dbg-l3-library-one-copy-too-many  (debug, L3, from app/app-l3-library-loans)

## bug0 [off-by-one]: availability check uses < 0 instead of <= 0, so a book with no copies left can still be checked out
- main.jac: fix by restoring
```
if b is None or available_copies(b) <= 0 {
```
(injected as)
```
if b is None or available_copies(b) < 0 {
```

