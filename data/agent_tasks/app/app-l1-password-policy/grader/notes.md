# app-l1-password-policy (level 1)

Domain: password policy validation. Reference solution: grader/reference/ (overlaid on starter/).

Hidden checks: grader/tests.jac imports the target module by the names the request states and asserts behavior (tolerances on floats). Gates: check, test.

Design latitude: only the names/fields/paths/shapes the request states are pinned; internal node/edge layout, helper names, and walker-vs-traversal structure are free.
