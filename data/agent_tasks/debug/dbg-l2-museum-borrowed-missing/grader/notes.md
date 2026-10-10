# dbg-l2-museum-borrowed-missing  (debug, L2, from native/nat-l2-museum-loans)

## bug0 [edge-direction]: incoming loans traversed as outgoing edges from the museum, which never match
- collection.jac: fix by restoring
```
for art in [here <-:LoanedTo:start_year <= y, end_year >= y:<-] {
```
(injected as)
```
for art in [here ->:LoanedTo:start_year <= y, end_year >= y:->] {
```

