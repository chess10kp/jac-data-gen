The orchard forecasting code is spread across `model/varieties.jac` (varieties, mature yields, the age curve), `model/orchard.jac` (blocks → rows → trees and `plant_block`) and `harvest.jac` (the `ForecastBlock` walker).

There are no tests at all. I'd like a single test module `harvest_tests.jac` in the project root that checks the age curve at its boundaries, the per-variety yields, diseased trees being excluded, totals across multiple rows, and that a forecast only covers the block it was spawned on. Please don't change the existing modules.
