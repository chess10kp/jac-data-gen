# dbg-l2-family-wrong-direction  (debug, L2, from native/nat-l2-family-cousins)

## bug0 [edge-direction]: grandparents computed by walking ParentOf edges forward (to grandchildren) instead of backward
- family.jac: fix by restoring
```
grandparents = [me <-:ParentOf:<- <-:ParentOf:<-];
```
(injected as)
```
grandparents = [me ->:ParentOf:-> ->:ParentOf:->];
```

