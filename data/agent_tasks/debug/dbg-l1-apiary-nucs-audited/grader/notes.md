# dbg-l1-apiary-nucs-audited  (debug, L1, from native/nat-l1-apiary-requeen)

## bug0 [traversal-depth]: the Hive ability keeps visiting outgoing Hive nodes, so nucleus hives hung off a hive get audited
- apiary.jac: fix by restoring
```
        self.checked += 1;
```
(injected as)
```
        self.checked += 1;
        visit [-->[?:Hive]];
```

