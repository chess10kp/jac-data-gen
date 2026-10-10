# dbg-l4-orchard-forecast-low  (debug, L4, from native/nat-l4-orchard-forecast)

## bug0 [accumulator-overwrite]: per-variety kg is overwritten by each tree instead of summed
- harvest.jac: fix by restoring
```
self.kg[name] = self.kg.get(name, 0.0) + MATURE_KG[name] * age_factor(here.age);
```
(injected as)
```
self.kg[name] = MATURE_KG[name] * age_factor(here.age);
```

## bug1 [statement-order]: trees counted before the diseased early-return
- harvest.jac: fix by restoring
```
        self.counted += 1;
    }
```
(injected as)
```
    }
```
- harvest.jac: fix by restoring
```
        if here.diseased {
            return;
        }
```
(injected as)
```
        self.counted += 1;
        if here.diseased {
            return;
        }
```

