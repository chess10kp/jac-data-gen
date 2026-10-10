# tg-l4-warehouse-pick

Source: derived:native/nat-l4-warehouse-picking (validated reference; oracle = its hidden tests).
Gate: suite must pass on original and kill >= 80% of grader/mutants.jsonl.

Mutant stats (CI 38067639465): {"n_candidates": 0, "n_stillborn": 0, "n_presumed_equivalent": 0, "n_eligible": 0, "ref_kill": null, "oracle_kill": null, "trivial_kill": null, "starter_kill": null, "ref_survivors": []}

Presumed-equivalent candidates (survived oracle AND reference, dropped): 

NOT VALIDATED: code seed.jac fails jac check: .jac - 1 error, 0 warnings
============================== 1 failed in 0.93s ===============================
✖ Error: error[E1096]: Connection left operand must be a node instance
  --> seed.jac:14:13
   12 |             first = aisle;
   13 |         } else {
   14 |             prev +>:NextAisle():+> aisle;
      |             ^^^^
   15 |         }
   16 |         for (code, sku, qty) in bins {

