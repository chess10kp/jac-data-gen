# dbg-l1-kiln-yield-rounding  (debug, L1, from native/nat-l1-kiln-cone-yield)

## bug0 [numeric-rounding]: yield is rounded instead of floored
- kiln.jac: fix by restoring
```
s.yield_pct = (s.pieces - s.losses) * 100 // s.pieces;
```
(injected as)
```
s.yield_pct = round((s.pieces - s.losses) * 100 / s.pieces);
```

