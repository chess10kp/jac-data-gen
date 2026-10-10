# dbg-l1-seedvault-examined-retired  (debug, L1, from native/nat-l1-seed-vault-regrow)

## bug0 [statement-order]: examined counter incremented before the retired-lot early return
- vault.jac: fix by restoring
```
        if here.retired {
            return;
        }
        self.examined += 1;
```
(injected as)
```
        self.examined += 1;
        if here.retired {
            return;
        }
```

