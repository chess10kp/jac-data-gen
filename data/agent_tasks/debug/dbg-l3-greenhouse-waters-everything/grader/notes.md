# dbg-l3-greenhouse-waters-everything  (debug, L3, from native/nat-l3-greenhouse-watering)

## bug0 [missing-filter]: WaterBed visits every bed instead of only the requested one
- greenhouse.jac: fix by restoring
```
visit [-->[?:Bed, code == self.bed]];
```
(injected as)
```
visit [-->[?:Bed]];
```

