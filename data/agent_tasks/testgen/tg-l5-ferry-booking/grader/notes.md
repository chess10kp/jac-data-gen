# tg-l5-ferry-booking

Source: derived:native/nat-l5-ferry-booking (validated reference; oracle = its hidden tests).
Gate: suite must pass on original and kill >= 80% of grader/mutants.jsonl.

Mutant stats (CI 38067639465): {"n_candidates": 0, "n_stillborn": 0, "n_presumed_equivalent": 0, "n_eligible": 0, "ref_kill": null, "oracle_kill": null, "trivial_kill": null, "starter_kill": null, "ref_survivors": []}

Presumed-equivalent candidates (survived oracle AND reference, dropped): 

NOT VALIDATED: code app.jac fails jac check:  124 |     can start with Root entry {
⚠ warning[W1037]: Explicit 'any' type annotation disables type checking here; consider a more specific type
  --> app.jac:138:59
  136 | 
  137 |     can finish with Root exit {
  138 |         report sorted(self.rows, key=lambda (r: dict[str, any]) { r["code"]; });
      |                                                           ^^^
  139 |     }
  140 | }
; oracle suite does not pass on original: ==== ERRORS ====================================
_______________________ ERROR collecting ferry_tests.jac _______________________
failed to import Jac test module /tmp/tg_tg-l5-ferry-booking_cp8msyw_/ferry_tests.jac: ModuleNotFoundError: No module named 'jaclang.testing'
=========================== short test summary info ============================
ERROR ferry_tests.jac - failed to import Jac test module /tmp/tg_tg-l5-ferry-booking_cp8msyw_/ferry_tests.jac: ModuleNotFoundError: No module named 'jaclang.testing'
=============================== 1 error in 2.39s ===============================

