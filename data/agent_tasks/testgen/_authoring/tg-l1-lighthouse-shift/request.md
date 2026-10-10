Hi! `keepers.jac` tracks lamp burn hours at our lighthouse stations. The `NightShift` walker adds a night's hours to every lit lamp (first-order lenses wear 1.5x faster) and reports which lamps are due for a bulb change.

Could you write tests for it in a new file `keepers_tests.jac`? I'd like the suite to be strict enough that any change to the wear factor, the 90% due threshold, the handling of unlit lamps, or the report format would make a test fail. The code itself is fine — please don't edit it.
