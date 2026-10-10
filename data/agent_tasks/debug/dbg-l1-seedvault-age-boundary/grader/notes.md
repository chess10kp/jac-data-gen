# dbg-l1-seedvault-age-boundary  (debug, L1, from native/nat-l1-seed-vault-regrow)

## bug0 [off-by-one]: age rule uses > 10 instead of >= 10
- vault.jac: fix by restoring
```
self.year - here.banked_year >= 10
```
(injected as)
```
self.year - here.banked_year > 10
```

