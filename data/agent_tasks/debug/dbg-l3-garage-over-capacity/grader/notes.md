# dbg-l3-garage-over-capacity  (debug, L3, from native/nat-l3-parking-garage)

## bug0 [off-by-one]: capacity check uses <= so each level accepts one car more than it has spots
- garage.jac: fix by restoring
```
if len([lvl ->:ParkedOn:->]) < lvl.spots {
```
(injected as)
```
if len([lvl ->:ParkedOn:->]) <= lvl.spots {
```

