# dbg-l2-watershed-double-count  (debug, L2, from native/nat-l2-watershed-upstream)

## bug0 [inconsistent-key]: visited set is filled with names but checked with jid, so braided reaches are counted twice
- watershed.jac: fix by restoring
```
        self.seen.add(key);
```
(injected as)
```
        self.seen.add(here.name);
```

