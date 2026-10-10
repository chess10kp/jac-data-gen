# dbg-l5-bikeshare-repeat-riders  (debug, L5, from native/nat-l5-bikeshare-api)

## bug0 [get-or-create]: rent always creates a new Rider node instead of reusing the existing one
- app.jac: fix by restoring
```
        if rd is None {
            rd = root ++> Rider(name=self.rider);
        }
```
(injected as)
```
        rd = root ++> Rider(name=self.rider);
```

## bug1 [wrong-sort-key]: least-worn ordering sorts by serial first instead of km first
- app.jac: fix by restoring
```
key=lambda (b: Bike) { (b.km, b.serial); }
```
(injected as)
```
key=lambda (b: Bike) { (b.serial, b.km); }
```

