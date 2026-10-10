# app-l3-fuel-economy (level 3)

Domain: vehicle fuel economy log. Reference solution: grader/reference/ (overlaid on starter/).

Hidden checks: (1) grader/tests.jac spawns the named walkers on `root` with uuid-unique names and asserts deltas only (store persists between runs); list reports may be one list or per-item. (2) grader/behavioral.py drives the CLI as separate `jac run main.jac ...` processes in a fresh temp dir (fresh cwd = empty graph) so state must persist on root across processes; output matching is case-insensitive substring/number based. Gates: check, test, run (every CLI call exits 0), behavioral.

Design latitude: only the names/fields/paths/shapes the request states are pinned; internal node/edge layout, helper names, and walker-vs-traversal structure are free.
