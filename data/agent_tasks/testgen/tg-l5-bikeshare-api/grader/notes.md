# tg-l5-bikeshare-api

Source: derived:native/nat-l5-bikeshare-api (validated reference; oracle = its hidden tests).
Gate: suite must pass on original and kill >= 80% of grader/mutants.jsonl.

Mutant stats (CI 38067639465): {"n_candidates": 0, "n_stillborn": 0, "n_presumed_equivalent": 0, "n_eligible": 0, "ref_kill": null, "oracle_kill": null, "trivial_kill": null, "starter_kill": null, "ref_survivors": []}

Presumed-equivalent candidates (survived oracle AND reference, dropped): 

NOT VALIDATED: reference suite fails jac check: app_tests.jac: notation to the relevant declaration (e.g., 'list[Task]' instead of bare 'list', or annotating an unannotated parameter or attribute). Can also indicate an unresolved import, a forward reference the checker cannot bind, or fallout from an upstream error.
⚠ warning[W1051]: Expression type could not be resolved (Unknown)
  --> app_tests.jac:153:9
  151 |         assert rows2[0]["free"] == 0;
  152 |     } finally {
  153 |         c.close();
      |         ^^^^^^^^^
  154 |     }
  155 | }
help: Often fixed by adding a more specific type annotation to the relevant declaration (e.g., 'list[Task]' instead of bare 'list', or annotating an unannotated parameter or attribute). Can also indicate an unresolved import, a forward reference the checker cannot bind, or fallout from an upstream error.
; ref suite does not pass on original: ========== ERRORS ====================================
________________________ ERROR collecting app_tests.jac ________________________
failed to import Jac test module /tmp/tg_tg-l5-bikeshare-api_o5gayvgq/app_tests.jac: ModuleNotFoundError: No module named 'jaclang.testing'
=========================== short test summary info ============================
ERROR app_tests.jac - failed to import Jac test module /tmp/tg_tg-l5-bikeshare-api_o5gayvgq/app_tests.jac: ModuleNotFoundError: No module named 'jaclang.testing'
=============================== 1 error in 2.32s ===============================
; oracle suite does not pass on original: ========== ERRORS ====================================
________________________ ERROR collecting app_tests.jac ________________________
failed to import Jac test module /tmp/tg_tg-l5-bikeshare-api_tf_6wbsi/app_tests.jac: ModuleNotFoundError: No module named 'jaclang.testing'
=========================== short test summary info ============================
ERROR app_tests.jac - failed to import Jac test module /tmp/tg_tg-l5-bikeshare-api_tf_6wbsi/app_tests.jac: ModuleNotFoundError: No module named 'jaclang.testing'
=============================== 1 error in 2.08s ===============================
; trivial suite does not pass on original: _________________ ERROR collecting app_tests.jac ________________________
failed to import Jac test module /tmp/tg_tg-l5-bikeshare-api_upkxs1jd/app_tests.jac: ImportError: No bytecode found for /tmp/tg_tg-l5-bikeshare-api_upkxs1jd/app_tests.jac
=========================== short test summary info ============================
ERROR app_tests.jac - failed to import Jac test module /tmp/tg_tg-l5-bikeshare-api_upkxs1jd/app_tests.jac: ImportError: No bytecode found for /tmp/tg_tg-l5-bikeshare-api_upkxs1jd/app_tests.jac
=============================== 1 error in 2.50s ===============================

