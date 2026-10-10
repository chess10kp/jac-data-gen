# tg-l3-library-loans

Source: derived:app/app-l3-library-loans (validated reference; oracle = its hidden tests).
Gate: suite must pass on original and kill >= 80% of grader/mutants.jsonl.

Mutant stats (CI 38067639465): {"n_candidates": 0, "n_stillborn": 0, "n_presumed_equivalent": 0, "n_eligible": 0, "ref_kill": null, "oracle_kill": null, "trivial_kill": null, "starter_kill": null, "ref_survivors": []}

Presumed-equivalent candidates (survived oracle AND reference, dropped): 

NOT VALIDATED: ref suite does not pass on original: g-l3-library-loans_29riq55b/library_tests.jac: ImportError: /tmp/tg_tg-l3-library-loans_29riq55b/main.jac failed to compile:
error[E5043]: Bytecode compilation failed: expression which can't be assigned to in Del context
  --> /tmp/tg_tg-l3-library-loans_29riq55b/main.jac:1:1
    1 | """Community lending library: Book/Member nodes, Loan edges, walker API + CLI."""
      | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    2 | 
    3 | import sys;
    4 | import datetime;
    5 |
=============================== 1 error in 2.71s ===============================
; oracle suite does not pass on original: g-l3-library-loans_jb7cjwex/library_tests.jac: ImportError: /tmp/tg_tg-l3-library-loans_jb7cjwex/main.jac failed to compile:
error[E5043]: Bytecode compilation failed: expression which can't be assigned to in Del context
  --> /tmp/tg_tg-l3-library-loans_jb7cjwex/main.jac:1:1
    1 | """Community lending library: Book/Member nodes, Loan edges, walker API + CLI."""
      | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    2 | 
    3 | import sys;
    4 | import datetime;
    5 |
=============================== 1 error in 2.59s ===============================
; trivial suite does not pass on original: R collecting library_tests.jac ______________________
failed to import Jac test module /tmp/tg_tg-l3-library-loans_q4vrh596/library_tests.jac: ImportError: No bytecode found for /tmp/tg_tg-l3-library-loans_q4vrh596/library_tests.jac
=========================== short test summary info ============================
ERROR library_tests.jac - failed to import Jac test module /tmp/tg_tg-l3-library-loans_q4vrh596/library_tests.jac: ImportError: No bytecode found for /tmp/tg_tg-l3-library-loans_q4vrh596/library_tests.jac
=============================== 1 error in 2.96s ===============================

