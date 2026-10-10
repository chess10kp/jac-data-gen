# dbg-l1-choir-or-and  (debug, L1, from native/nat-l1-choir-sections)

## bug0 [boolean-logic]: `and` replaced by `or` in the eligibility condition
- choir.jac: fix by restoring
```
if here.active and here.rehearsals >= 2 {
```
(injected as)
```
if here.active or here.rehearsals >= 2 {
```

