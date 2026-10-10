# dbg-l3-radio-summary-keyerror  (debug, L3, from native/nat-l3-radio-contest-log)

## bug0 [crash-missing-init]: summary accumulates with += into a dict key that was never initialised (KeyError)
- contest.jac: fix by restoring
```
self.counts[here.band.name] = len([here ->:Logged:->]);
```
(injected as)
```
self.counts[here.band.name] += len([here ->:Logged:->]);
```

