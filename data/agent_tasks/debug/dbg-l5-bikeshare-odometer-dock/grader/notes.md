# dbg-l5-bikeshare-odometer-dock  (debug, L5, from native/nat-l5-bikeshare-api)

## bug0 [assign-vs-accumulate]: return overwrites the odometer with the trip distance instead of adding it
- app.jac: fix by restoring
```
bike.km += self.km;
```
(injected as)
```
bike.km = self.km;
```

## bug1 [off-by-one]: full-station check uses > so a full station accepts one more bike
- app.jac: fix by restoring
```
if len([st ->:Docked:->]) >= st.capacity {
```
(injected as)
```
if len([st ->:Docked:->]) > st.capacity {
```

