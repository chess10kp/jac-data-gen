# dbg-l1-choir-minimum-inclusive  (debug, L1, from native/nat-l1-choir-sections)

## bug0 [off-by-one]: short list uses <= minimum instead of < minimum
- choir.jac: fix by restoring
```
if self.counts[p.name] < self.minimum {
```
(injected as)
```
if self.counts[p.name] <= self.minimum {
```

