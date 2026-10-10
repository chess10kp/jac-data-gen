# dbg-l1-apiary-healthy-flagged  (debug, L1, from native/nat-l1-apiary-requeen)

## bug0 [boolean-logic]: negation applied to the whole conjunction instead of queen_seen only
- apiary.jac: fix by restoring
```
queenless_and_weak = not here.queen_seen and here.brood_frames < 3;
```
(injected as)
```
queenless_and_weak = not (here.queen_seen and here.brood_frames < 3);
```

