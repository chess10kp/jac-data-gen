# dbg-l2-pantry-orphan-ingredients  (debug, L2, from native/nat-l2-pantry-substitutes)

## bug0 [persistence-not-attached]: new Ingredient nodes are not connected to root, so get-or-create never finds them and substitutes attach to duplicate nodes
- cookbook.jac: fix by restoring
```
    return root ++> Ingredient(name=label);
```
(injected as)
```
    return Ingredient(name=label);
```

