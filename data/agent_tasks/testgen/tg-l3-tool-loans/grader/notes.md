# tg-l3-tool-loans

Source: derived:native/nat-l3-tool-library (validated reference; oracle = its hidden tests).
Gate: suite must pass on original and kill >= 80% of grader/mutants.jsonl.

Mutant stats (CI 38067639465): {"n_candidates": 0, "n_stillborn": 0, "n_presumed_equivalent": 0, "n_eligible": 0, "ref_kill": null, "oracle_kill": null, "trivial_kill": null, "starter_kill": null, "ref_survivors": []}

Presumed-equivalent candidates (survived oracle AND reference, dropped): 

NOT VALIDATED: ref suite does not pass on original: ib_tests.jac: ImportError: /tmp/tg_tg-l3-tool-loans_ww6ntnuo/toollib.jac failed to compile:
error[E5043]: Bytecode compilation failed: expression which can't be assigned to in Del context
  --> /tmp/tg_tg-l3-tool-loans_ww6ntnuo/toollib.jac:1:1
    1 | """Neighbourhood tool library: tools and members live on root; loans are Lent edges."""
      | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    2 | 
    3 | node Tool {
    4 |     has code: str;
    5 |     has name: str;
=============================== 1 error in 2.72s ===============================
; oracle suite does not pass on original: ib_tests.jac: ImportError: /tmp/tg_tg-l3-tool-loans_ajabl4_o/toollib.jac failed to compile:
error[E5043]: Bytecode compilation failed: expression which can't be assigned to in Del context
  --> /tmp/tg_tg-l3-tool-loans_ajabl4_o/toollib.jac:1:1
    1 | """Neighbourhood tool library: tools and members live on root; loans are Lent edges."""
      | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    2 | 
    3 | node Tool {
    4 |     has code: str;
    5 |     has name: str;
=============================== 1 error in 2.69s ===============================
; trivial suite does not pass on original: _______ ERROR collecting toollib_tests.jac ______________________
failed to import Jac test module /tmp/tg_tg-l3-tool-loans_8t57oljn/toollib_tests.jac: ImportError: No bytecode found for /tmp/tg_tg-l3-tool-loans_8t57oljn/toollib_tests.jac
=========================== short test summary info ============================
ERROR toollib_tests.jac - failed to import Jac test module /tmp/tg_tg-l3-tool-loans_8t57oljn/toollib_tests.jac: ImportError: No bytecode found for /tmp/tg_tg-l3-tool-loans_8t57oljn/toollib_tests.jac
=============================== 1 error in 2.50s ===============================

