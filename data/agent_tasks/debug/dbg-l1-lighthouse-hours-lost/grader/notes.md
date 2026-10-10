# dbg-l1-lighthouse-hours-lost  (debug, L1, from native/nat-l1-lighthouse-lamps)

## bug0 [persistence-local-copy]: burn time is accumulated into a local variable and never written back to the Lamp node
- keepers.jac: fix by restoring
```
        here.burn_hours += self.hours * factor;
        if here.burn_hours >= 0.9 * here.rated_hours {
```
(injected as)
```
        total = here.burn_hours + self.hours * factor;
        if total >= 0.9 * here.rated_hours {
```

