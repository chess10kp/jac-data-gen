# dbg-l1-kiln-totals-reset  (debug, L1, from native/nat-l1-kiln-cone-yield)

## bug0 [accumulator-reset]: the per-cone stat is re-created for every firing, discarding earlier loads
- kiln.jac: fix by restoring
```
        if here.cone not in self.totals {
            self.totals[here.cone] = ConeStat(cone=here.cone, pieces=0, losses=0, yield_pct=0);
        }
```
(injected as)
```
        self.totals[here.cone] = ConeStat(cone=here.cone, pieces=0, losses=0, yield_pct=0);
```

