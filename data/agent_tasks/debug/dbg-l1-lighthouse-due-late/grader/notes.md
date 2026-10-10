# dbg-l1-lighthouse-due-late  (debug, L1, from native/nat-l1-lighthouse-lamps)

## bug0 [statement-order]: due check runs before tonight's hours are added, so lamps appear one night late
- keepers.jac: fix by restoring
```
        here.burn_hours += self.hours * factor;
        if here.burn_hours >= 0.9 * here.rated_hours {
            self.due.append(here.station);
        }
```
(injected as)
```
        if here.burn_hours >= 0.9 * here.rated_hours {
            self.due.append(here.station);
        }
        here.burn_hours += self.hours * factor;
```

