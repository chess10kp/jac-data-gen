Fuel economy tracker for our two delivery vans, as a Jac CLI (the project is scaffolded already with `jac create`).

Store each vehicle as a node under root, keyed by plate (case-insensitive, store upper-case), and every fill-up as a node connected to its vehicle with the odometer reading (km) and liters added. It must remember everything between runs.

Rules:
- fill-ups always fill the tank to full
- economy is liters per 100 km: (sum of liters of every fill-up except the first) / (last odometer − first odometer) × 100, rounded to 2 decimals. With fewer than two fill-ups it's `0.0`.
- an odometer reading that isn't greater than the vehicle's latest reading is rejected
- recording a fill-up for a plate that hasn't been added is rejected

Walkers (in `main.jac`):
- `AddVehicle` — `plate: str`
- `RecordFill` — `plate: str`, `odometer: int`, `liters: float`; reports a dict with `ok` (bool) and `error` (string, only when not ok)
- `Economy` — `plate: str`; reports the float

Commands:
```
jac run main.jac add <plate>
jac run main.jac fill <plate> <odometer> <liters>    # prints "ok" or "error: <reason>"
jac run main.jac economy <plate>                     # prints "<plate> <value> L/100km"
```
