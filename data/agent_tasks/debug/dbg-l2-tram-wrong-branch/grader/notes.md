# dbg-l2-tram-wrong-branch  (debug, L2, from native/nat-l2-tram-lines)

## bug0 [missing-edge-filter]: next stop is chosen among all outgoing tracks instead of the requested line's
- tramway.jac: fix by restoring
```
            nxt = [here ->:Track:line == self.line:->];
```
(injected as)
```
            nxt = [here ->:Track:->];
```

