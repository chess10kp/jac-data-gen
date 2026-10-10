# dbg-l2-museum-conservation-borrowed  (debug, L2, from native/nat-l2-museum-loans)

## bug0 [missing-condition]: conservation check applied to owned works only; borrowed works in conservation are still listed
- collection.jac: fix by restoring
```
            if not art.in_conservation {
                titles.add(art.title);
            }
        }
        self.shown
```
(injected as)
```
            titles.add(art.title);
        }
        self.shown
```

