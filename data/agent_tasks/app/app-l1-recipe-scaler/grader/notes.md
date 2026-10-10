# app-l1-recipe-scaler (level 1)

Domain: cooking unit conversion / recipe scaling. Reference solution: grader/reference/ (overlaid on starter/).

Hidden checks: grader/tests.jac imports the target module by the names the request states and asserts behavior (tolerances on floats). Gates: check, test.

Design latitude: only the names/fields/paths/shapes the request states are pinned; internal node/edge layout, helper names, and walker-vs-traversal structure are free.
