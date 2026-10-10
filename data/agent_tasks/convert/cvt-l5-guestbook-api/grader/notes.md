# cvt-l5-guestbook-api
Source okteto/guestbook-api (MIT) @46e2dc7. FARM L5: ODMantic Entry -> node, 4 FastAPI routes ->
walker:pub endpoints. Hidden tests: grader/tests.jac (in-process spawns, delta/uuid-tagged since the
graph store persists) + grader/smoke.py (HTTP replay of upstream test_e2e.py over `jac start`).
Quirk exercised: `entry` is a Jac keyword -> field must be declared with backtick escape `` `entry ``.
Negatives: hollow create (node not attached), delete-all, no-op delete, swapped fields.
