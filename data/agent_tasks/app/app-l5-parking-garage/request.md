Need a backend for a small parking garage's entry/exit kiosks. Jac service project is already here (from `jac create --kind service`).

Public function endpoints (`def:pub`, i.e. `POST /function/<name>`):

- `set_capacity(spots: int) -> occupancy` — configure the number of spots (≥ 1). Lowering it below the number of currently parked cars is an error.
- `park(plate: str, at: str)` — a car enters at time `at` ("HH:MM", same day). Plates are case-insensitive, stored upper-case. Returns `{"plate": ..., "entered": ...}`.
- `leave(plate: str, at: str)` — car exits. Returns `{"plate": ..., "minutes": <int>, "fee": <float>}`.
- `occupancy()` — returns `{"capacity": int, "occupied": int, "free": int, "plates": [sorted plates parked now]}`.

Fee: the first 30 minutes are free; past that it's 2.00 per started hour of the whole stay (31 min → 2.00, 60 min → 2.00, 61 min → 4.00).

Errors — return `{"error": "<message>"}`: garage full (or capacity never set), a plate that's already parked trying to park again, leaving with a plate that isn't parked, a leave time before the entry time, bad time format.

Keep the garage config, the cars currently parked, and a history of completed stays on the graph under root (history doesn't need an endpoint yet). Tests please, and make sure it boots with `jac run`.
