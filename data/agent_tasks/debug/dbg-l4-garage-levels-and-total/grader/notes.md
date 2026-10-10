# dbg-l4-garage-levels-and-total  (debug, L4, from native/nat-l3-parking-garage)

## bug0 [missing-sort]: levels tried in creation order instead of lowest number first
- garage.jac: fix by restoring
```
for lvl in sorted([root -->[?:Level]], key=lambda (l: Level) { l.number; }) {
```
(injected as)
```
for lvl in [root -->[?:Level]] {
```

## bug1 [accumulator-overwrite]: occupancy total overwritten per level instead of summed
- garage.jac: fix by restoring
```
self.total += n;
```
(injected as)
```
self.total = n;
```

