# dbg-l1-shipping-tiny-parcel  (debug, L1, from app/app-l1-shipping-quote)

## bug0 [missing-clamp]: extra-weight term not clamped at zero, so parcels under 1 kg get a discount below the base price
- shipping.jac: fix by restoring
```
return round(base + max(0.0, weight_kg - 1) * per_kg, 2);
```
(injected as)
```
return round(base + (weight_kg - 1) * per_kg, 2);
```

