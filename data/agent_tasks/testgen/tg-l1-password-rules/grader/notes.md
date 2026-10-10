# tg-l1-password-rules

Source: derived:app/app-l1-password-policy (validated reference; oracle = its hidden tests).
Gate: suite must pass on original and kill >= 80% of grader/mutants.jsonl.

Mutant stats (CI 38067639465): {"n_candidates": 0, "n_stillborn": 0, "n_presumed_equivalent": 0, "n_eligible": 0, "ref_kill": null, "oracle_kill": null, "trivial_kill": null, "starter_kill": null, "ref_survivors": []}

Presumed-equivalent candidates (survived oracle AND reference, dropped): 

NOT VALIDATED: ref suite does not pass on original: 7 in _multicall
    raise exception
  /home/runner/.cache/jac/rt/553c250071fd962f-6283dfd564ffd55e/site/_pytest/runner.py:194 in pytest_runtest_call
    raise
  /tmp/tg_tg-l1-password-rules_y5j8d9q5/passcheck_tests.jac:2 in test_space_counts_as_a_symbol
  /home/runner/work/jac/jac/.zig-cache/o/6edb7cbd97002ba0eda0926eff21a4d4/payload.tar.zst.work/site/jaclang/runtimelib/impl/test.impl.jac:207 in invoke_native_test
E   AssertionError: assertion failed at /tmp/tg_tg-l1-password-rules_y5j8d9q5/passcheck_tests.jac:20
========================= 7 failed, 1 passed in 7.60s ==========================
; oracle suite does not pass on original: rs.py:167 in _multicall
    raise exception
  /home/runner/.cache/jac/rt/553c250071fd962f-6283dfd564ffd55e/site/_pytest/runner.py:194 in pytest_runtest_call
    raise
  /tmp/tg_tg-l1-password-rules_golnxyzk/passcheck_tests.jac:2 in test_strength_buckets
  /home/runner/work/jac/jac/.zig-cache/o/6edb7cbd97002ba0eda0926eff21a4d4/payload.tar.zst.work/site/jaclang/runtimelib/impl/test.impl.jac:207 in invoke_native_test
E   AssertionError: assertion failed at /tmp/tg_tg-l1-password-rules_golnxyzk/passcheck_tests.jac:31
========================= 3 failed, 2 passed in 5.88s ==========================

