# dbg-l4-panel-load-voltage  (debug, L4, from native/nat-l4-panel-load)

## bug0 [ignored-parameter]: amps computed with a hard-coded 120 V instead of the walker's volts
- load.jac: fix by restoring
```
amps = round(watts / self.volts, 2);
```
(injected as)
```
amps = round(watts / 120.0, 2);
```

## bug1 [off-by-one]: overload threshold inclusive (>=) instead of strictly above 80%
- load.jac: fix by restoring
```
if amps > 0.8 * here.amps {
```
(injected as)
```
if amps >= 0.8 * here.amps {
```

