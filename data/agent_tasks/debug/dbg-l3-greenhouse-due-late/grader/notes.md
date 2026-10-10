# dbg-l3-greenhouse-due-late  (debug, L3, from native/nat-l3-greenhouse-watering)

## bug0 [off-by-one]: due test uses > interval instead of >= interval
- greenhouse.jac: fix by restoring
```
>= p.interval_days
```
(injected as)
```
> p.interval_days
```

