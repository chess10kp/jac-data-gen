# dbg-l4-warehouse-pick-stops-early  (debug, L4, from native/nat-l4-warehouse-picking)

## bug0 [aliasing]: walker works directly on the caller's order dict instead of a copy
- picking.jac: fix by restoring
```
self.outstanding = dict(self.order);
```
(injected as)
```
self.outstanding = self.order;
```

## bug1 [any-vs-all]: pick run stops as soon as one SKU is complete (all) instead of continuing while any SKU is outstanding
- picking.jac: fix by restoring
```
if any([n > 0 for n in self.outstanding.values()]) {
```
(injected as)
```
if all([n > 0 for n in self.outstanding.values()]) {
```

