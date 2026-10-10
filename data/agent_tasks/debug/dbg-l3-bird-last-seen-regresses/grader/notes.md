# dbg-l3-bird-last-seen-regresses  (debug, L3, from native/nat-l3-bird-survey)

## bug0 [wrong-aggregate]: last_day takes the latest submission instead of the max day
- survey.jac: fix by restoring
```
link.last_day = max(link.last_day, self.day);
```
(injected as)
```
link.last_day = self.day;
```

