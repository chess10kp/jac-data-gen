# dbg-l5-dog-boarding-vacancy  (debug, L5, from native/nat-l5-dog-boarding)

## bug0 [off-by-one]: overlap test treats back-to-back stays (one ends the night before the other starts) as overlapping
- app.jac: fix by restoring
```
start < s.start + s.nights
```
(injected as)
```
start <= s.start + s.nights
```

## bug1 [wrong-sort-key]: run preference sorts by code before size, so larger runs are picked before fitting smaller ones
- app.jac: fix by restoring
```
key=lambda (r: Run) { (r.size.value, r.code); }
```
(injected as)
```
key=lambda (r: Run) { (r.code, r.size.value); }
```

