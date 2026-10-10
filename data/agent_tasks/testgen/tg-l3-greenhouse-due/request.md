Need tests for the greenhouse watering module (`greenhouse.jac`). Specifically the `WaterBed` and `DueOn` walkers — those are what the morning rota is printed from, and a wrong "due" list means dead seedlings. (`PlantIn` you can use for setup; `Uproot` is out of scope.)

Please put them in `greenhouse_tests.jac`. Cover: what counts as due (interval reached vs not yet), that watering only resets plants in the named bed, the count `WaterBed` reports, unknown beds, and the `bed/species` output format and ordering. Don't edit the module.
