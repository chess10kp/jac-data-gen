`main.jac` is a small fleet fuel log: `AddVehicle`, `RecordFill` and `Economy` walkers (plus a CLI wrapper you can ignore). There are no tests for the walkers.

Write `fuel_tests.jac` for them. The economy figure is litres per 100 km where the first fill-up's litres don't count (they filled the tank before the distance was driven) — please make sure that's pinned down, along with plate case-insensitivity, the odometer must-increase rule, unknown plates, and fills recorded out of order. Don't change `main.jac`.
