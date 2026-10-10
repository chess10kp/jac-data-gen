# dbg-l3-bird-species-duplicated  (debug, L3, from native/nat-l3-bird-survey)

## bug0 [persistence-not-attached]: new Species nodes are not attached to root, so every sighting creates a fresh species and a fresh edge
- survey.jac: fix by restoring
```
    return found[0] if found else root ++> Species(name=label);
```
(injected as)
```
    return found[0] if found else Species(name=label);
```

