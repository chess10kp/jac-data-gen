# app-l2-tram-network (level 2)

Domain: tram network shortest travel time. Reference solution: grader/reference/ (overlaid on starter/).

Hidden checks: grader/tests.jac builds transient graphs with the node/edge archetypes named in the request (no root persistence) and spawns the named walkers on a node, reading `.reports[0]` (the request says report once). Gates: check, test.

Design latitude: only the names/fields/paths/shapes the request states are pinned; internal node/edge layout, helper names, and walker-vs-traversal structure are free.
