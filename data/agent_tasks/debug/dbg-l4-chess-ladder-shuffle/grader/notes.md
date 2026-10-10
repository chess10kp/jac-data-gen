# dbg-l4-chess-ladder-shuffle  (debug, L4, from native/nat-l4-chess-ladder)

## bug0 [off-by-one]: rank shift excludes the defender (>= became >), leaving two players on the same rank
- challenge.jac: fix by restoring
```
if p.rank >= old_d and p.rank < old_c {
```
(injected as)
```
if p.rank > old_d and p.rank < old_c {
```

## bug1 [off-by-one]: range rule rejects a challenge exactly 3 rungs up
- challenge.jac: fix by restoring
```
if gap <= 0 or gap > 3 {
```
(injected as)
```
if gap <= 0 or gap >= 3 {
```

