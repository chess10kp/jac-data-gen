# dbg-l2-pantry-optional-blocks  (debug, L2, from native/nat-l2-pantry-substitutes)

## bug0 [missing-edge-filter]: Needs edges are not filtered on optional == False, so optional ingredients block recipes
- cookbook.jac: fix by restoring
```
[here ->:Needs:optional == False:->]
```
(injected as)
```
[here ->:Needs:->]
```

