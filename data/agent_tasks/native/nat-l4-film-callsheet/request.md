We're writing tooling for a film shoot. `crew.jac` defines crew members and their departments; `schedule.jac` holds the shooting schedule (`ShootDay` nodes on `root` that `Schedule` their `Scene`s, and `AssignedTo` edges from crew to the scenes they work on).

Please add a call-sheet generator:

1. In `crew.jac`, add a function `prep_minutes(dept: Department) -> int` giving how long before their first scene each department must arrive: MAKEUP 120, WARDROBE 90, CAMERA 60, everyone else 30.

2. Create `callsheet.jac` with a walker `CallSheet` (`has day: int`), spawned on `root`, which goes to that day's `ShootDay` and through its scenes. For every crew member assigned to at least one scene **that day**, their call time is (the start of their earliest scene that day) − `prep_minutes(their department)`. Report once a list of lines formatted as `"HH:MM Name (DEPT)"` (24-hour, zero-padded, department enum name), sorted by call time and then by name. Also set `locations: int` to the number of distinct scene locations that day. A day with nothing scheduled reports an empty list.

Scenes on other days must not affect a crew member's call time. Don't change `schedule.jac`.
