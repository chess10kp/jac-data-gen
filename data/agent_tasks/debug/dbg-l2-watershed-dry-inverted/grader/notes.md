# dbg-l2-watershed-dry-inverted  (debug, L2, from native/nat-l2-watershed-upstream)

## bug0 [inverted-filter]: dry-season traversal follows only seasonal channels instead of only permanent ones
- watershed.jac: fix by restoring
```
seasonal == False
```
(injected as)
```
seasonal == True
```

