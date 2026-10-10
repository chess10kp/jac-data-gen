# tg-l3-fuel-economy

Source: derived:app/app-l3-fuel-economy (validated reference; oracle = its hidden tests).
Gate: suite must pass on original and kill >= 80% of grader/mutants.jsonl.

Mutant stats (CI 38067639465): {"n_candidates": 0, "n_stillborn": 0, "n_presumed_equivalent": 0, "n_eligible": 0, "ref_kill": null, "oracle_kill": null, "trivial_kill": null, "starter_kill": null, "ref_survivors": []}

Presumed-equivalent candidates (survived oracle AND reference, dropped): 

NOT VALIDATED: reference suite fails jac check: fuel_tests.jac: ort "__contains__"; "Any" does not
  --> fuel_tests.jac:43:12
   41 |     same = fill("car1", 1000, 5.0);
   42 |     assert same["ok"] == False;
   43 |     assert "1000" in same["error"];
      |            ^^^^^^^^^^^^^^^^^^^^^^^
   44 |     back = fill("car1", 999, 5.0);
   45 |     assert back["ok"] == False;
⚠ warning[W1037]: Explicit 'any' type annotation disables type checking here; consider a more specific type
  --> fuel_tests.jac:3:51
    1 | import from main { Vehicle, FillUp, find_vehicle, fills_of, AddVehicle, RecordFill, Economy }
    2 | 
    3 | def fill(p: str, odo: int, l: float) -> dict[str, any] {
      |                                                   ^^^
    4 |     w = root spawn RecordFill(plate=p, odometer=odo, liters=l);
    5 |     assert len(w.reports) == 1;
; ref suite does not pass on original: y_dqxyeneg/fuel_tests.jac:87 in test_vehicles_do_not_share_fills
    fill("a", 0, 1.0);
  /tmp/tg_tg-l3-fuel-economy_dqxyeneg/fuel_tests.jac:4 in fill
    w = root spawn RecordFill(plate=p, odometer=odo, liters=l);
  /tmp/tg_tg-l3-fuel-economy_dqxyeneg/main.jac:47 in record
    fills = fills_of(v);
  /tmp/tg_tg-l3-fuel-economy_dqxyeneg/main.jac:24 in fills_of
    return sorted([f for f in [v -->[?:FillUp]]], key=lambda (f: FillUp) -> int { return f.odometer; });
E   NameError: name '__jac_lambda_1' is not defined
========================= 6 failed, 4 passed in 2.60s ==========================
; oracle suite does not pass on original: test/runner.py:194 in pytest_runtest_call
    raise
  /tmp/tg_tg-l3-fuel-economy_sm94h9ha/fuel_tests.jac:26 in test_plates_are_case_insensitive
    root spawn RecordFill(plate=p.upper(), odometer=100, liters=10.0);
  /tmp/tg_tg-l3-fuel-economy_sm94h9ha/main.jac:47 in record
    fills = fills_of(v);
  /tmp/tg_tg-l3-fuel-economy_sm94h9ha/main.jac:24 in fills_of
    return sorted([f for f in [v -->[?:FillUp]]], key=lambda (f: FillUp) -> int { return f.odometer; });
E   NameError: name '__jac_lambda_1' is not defined
========================= 3 failed, 1 passed in 2.25s ==========================

