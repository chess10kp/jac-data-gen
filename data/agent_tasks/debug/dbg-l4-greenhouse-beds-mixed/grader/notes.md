# dbg-l4-greenhouse-beds-mixed  (debug, L4, from native/nat-l3-greenhouse-watering)

## bug0 [wrong-field]: bed lookup in PlantIn compares the bed code against the species, so every planting creates a new bed
- greenhouse.jac: fix by restoring
```
beds = [root -->[?:Bed, code == self.bed]];
```
(injected as)
```
beds = [root -->[?:Bed, code == self.species]];
```

## bug1 [missing-filter]: Uproot pulls the species from every bed, not just the requested one
- greenhouse.jac: fix by restoring
```
for b in [root -->[?:Bed, code == self.bed]] {
```
(injected as)
```
for b in [root -->[?:Bed]] {
```

