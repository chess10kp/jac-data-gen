# dbg-l2-family-half-siblings  (debug, L2, from native/nat-l2-family-cousins)

## bug0 [wrong-predicate]: only full siblings are excluded; a half-sibling (one shared parent) is reported as a cousin
- family.jac: fix by restoring
```
            if not shared {
```
(injected as)
```
            if len(shared) < len(parents) {
```

