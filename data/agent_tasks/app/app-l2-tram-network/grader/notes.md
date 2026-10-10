# app-l2-tram-network (level 2)

Domain: tram network shortest travel time. Reference solution: grader/reference/ (overlaid on starter/).

Hidden checks: grader/tests.jac builds transient graphs with the node/edge archetypes named in the request (no root persistence) and spawns the named walkers on a node, reading `.reports[0]` (the request says report once). Gates: check, test.

Design latitude: only the names/fields/paths/shapes the request states are pinned; internal node/edge layout, helper names, and walker-vs-traversal structure are free.

Known toolchain hazard (jac 0.37.25): a pure-Jac module is auto-placed on the native backend; if one ability
uses a construct native can't lower (here the edge-object reference used to read Track.minutes) it is demoted
to Python and the mixed module SIGABRTs at run/test time with no output. The reference adds `import heapq;` (an import with no native-stdlib twin), which
places the whole module on the server backend. A candidate that hits the abort fails honestly (it is what a user
would see); `jac explain placement tram.jac` shows the demotion.
