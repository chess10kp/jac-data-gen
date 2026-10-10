# Shipping quote library (Jac)

We're replacing the printed rate card our warehouse uses to quote parcel shipping by hand. Please write the logic as a Jac module, `shipping.jac`, exposing three functions. No HTTP, no persistence — it'll be imported by other code later.

## `billable_weight(actual_kg: float, length_cm: float, width_cm: float, height_cm: float) -> float`

Carriers charge on whichever is larger: the actual weight or the volumetric weight (`length * width * height / 5000`). Round the result **up** to the next 0.5 kg (so 2.1 → 2.5, 2.5 → 2.5, 3.01 → 3.5). Any argument that is zero or negative is a `ValueError`.

## `quote(weight_kg: float, zone: str) -> float`

| zone | base price (covers the first 1 kg) | per additional kg |
|---|---|---|
| `domestic` | 5.00 | 1.20 |
| `regional` | 9.00 | 2.00 |
| `international` | 20.00 | 4.50 |

Additional weight is charged pro-rata (1.5 kg domestic = 5.00 + 0.5 × 1.20 = 5.60). Return the price rounded to 2 decimals. Unknown zone or a non-positive weight → `ValueError`.

## `free_shipping(order_total: float, zone: str) -> bool`

Domestic orders of 50.00 or more ship free, regional orders of 100.00 or more ship free, international never ships free. Unknown zone → `ValueError`.
