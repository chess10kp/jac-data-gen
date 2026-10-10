# app-l4-arcade-leaderboard (level 4)

Domain: arcade high score leaderboard API. Reference solution: grader/reference/ (overlaid on starter/).

Hidden checks: (1) the workspace's OWN test blocks must exist and pass (the request asks for tests); (2) grader/tests.jac imports the endpoint walker/functions and spawns/calls them in-process (dict-or-node tolerant via get()); (3) grader/smoke.py copies the workspace to a fresh dir, boots `jac start --port <free> main.jac` (jac 0.36.1), waits for /healthz and exercises the endpoint over HTTP asserting status + JSON shape across requests (persistence). Errors accepted as a report with `error`, ok=false envelope, or 4xx. Gates: check, test, start, behavioral.

Design latitude: only the names/fields/paths/shapes the request states are pinned; internal node/edge layout, helper names, and walker-vs-traversal structure are free.
