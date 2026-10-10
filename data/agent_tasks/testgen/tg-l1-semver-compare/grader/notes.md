# tg-l1-semver-compare

Source: derived:app/app-l1-semver-tools (validated reference; oracle = its hidden tests).
Gate: suite must pass on original and kill >= 80% of grader/mutants.jsonl.

Mutant stats (CI 38067639465): {"n_candidates": 0, "n_stillborn": 0, "n_presumed_equivalent": 0, "n_eligible": 0, "ref_kill": null, "oracle_kill": null, "trivial_kill": null, "starter_kill": null, "ref_survivors": []}

Presumed-equivalent candidates (survived oracle AND reference, dropped): 

NOT VALIDATED: ref suite does not pass on original: 55e/site/pluggy/_callers.py:167 in _multicall
    raise exception
  /home/runner/.cache/jac/rt/553c250071fd962f-6283dfd564ffd55e/site/_pytest/runner.py:194 in pytest_runtest_call
    raise
  /tmp/tg_tg-l1-semver-compare_0lzbzbz9/semver_compare_tests.jac:2 in test_max_satisfying_ignores_pre_releases_and_handles_empty
  /home/runner/work/jac/jac/.zig-cache/o/6edb7cbd97002ba0eda0926eff21a4d4/payload.tar.zst.work/site/jaclang/runtimelib/impl/test.impl.jac:207 in invoke_native_test
E   AssertionError: integer overflow
========================= 6 failed, 4 passed in 9.93s ==========================
; oracle suite does not pass on original: p/tg_tg-l1-semver-compare_u807cxmy/semver_compare_tests.jac preferred native but did not lower; compiled in the server codespace (error[E5092]: Native lowering failed for function 'testraises')
note: /tmp/tg_tg-l1-semver-compare_u807cxmy/semver_compare_tests.jac preferred native but did not lower; compiled in the server codespace (error[E5092]: Native lowering failed for function 'testraises')
note: /tmp/tg_tg-l1-semver-compare_u807cxmy/semver_compare_tests.jac preferred native but did not lower; compiled in the server codespace (error[E5092]: Native lowering failed for function 'testraises')

