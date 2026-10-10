Ferry booking code needs a cleanup pass before we add the freight deck. Right now it's two Python-style modules: `fleet.jac` keeps every sailing and booking in dicts on a single `Fleet` node (found with an `isinstance` loop), vehicles are plain strings, and `main.jac` loops over those dicts for every query.

Please restructure it as a small Jac project:
- a models module: vehicle type as an enum, sailings and bookings as nodes, and a typed edge from sailing to booking that records the lanes and seats the booking takes on that sailing;
- walkers (own module) for the sweeps across sailings — finding a booking by ref, the per-day passenger count;
- a service module with the operations;
- implementations moved into `.impl.jac` annexes, so the `.jac` files read as the interface.

No dict-typed fields left on nodes. `main.jac` stays the entry point and must keep exporting `add_sailing`, `book`, `cancel`, `move`, `manifest`, `free_space` and `day_passengers` with the same signatures and return values (status strings included).
