# dbg-l5-hackathon-scores-wrong  (debug, L5, from native/nat-l5-hackathon-judging)

## bug0 [missing-filter]: existing-score lookup ignores the criterion, so scoring a second criterion overwrites the first
- app.jac: fix by restoring
```
existing = [e for e in [edge j ->:Scored:-> t] if e.criterion == self.criterion];
```
(injected as)
```
existing = [e for e in [edge j ->:Scored:-> t]];
```

## bug1 [missing-condition]: empty track filter no longer means 'all tracks'
- app.jac: fix by restoring
```
if self.track and here.track != self.track {
```
(injected as)
```
if here.track != self.track {
```

