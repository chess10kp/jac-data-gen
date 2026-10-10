# dbg-l5-ferry-capacity-refs  (debug, L5, from native/nat-l5-ferry-booking)

## bug0 [missing-condition]: foot slots consumed by passengers of every booking, not only FOOT bookings
- app.jac: fix by restoring
```
return self.passengers if self.vehicle == Vehicle.FOOT else 0;
```
(injected as)
```
return self.passengers;
```

## bug1 [wrong-scope]: duplicate booking ref only checked on the requested sailing instead of across all sailings
- app.jac: fix by restoring
```
if [b for b in [root -->[?:Sailing] ->:Holds:->] if b.ref == self.ref] {
```
(injected as)
```
if [b for b in [s ->:Holds:->] if b.ref == self.ref] {
```

