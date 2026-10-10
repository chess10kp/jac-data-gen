# dbg-l3-garage-free-hour  (debug, L3, from native/nat-l3-parking-garage)

## bug0 [integer-division]: fee counts completed hours instead of started hours
- garage.jac: fix by restoring
```
fee = 3 * ((stay + 59) // 60);
```
(injected as)
```
fee = 3 * (stay // 60);
```

