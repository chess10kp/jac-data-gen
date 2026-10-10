judging code is one `main.jac` with an `Event` node full of dicts (team→track, judge→list of tracks, and a "judge|team" string-keyed score sheet dict), plus an isinstance loop to find it. it works but it's not Jac.

target: a proper multi-module layout —
- models: criterion as an enum; tracks, teams and judges as nodes; teams entered under their track, judges linked to the tracks they cover, and each score as a typed `judge → team` edge carrying the criterion and points
- walkers module: standings collection and a judge's backlog walk (judge → covered tracks → teams)
- service module with the operations
- bodies in `.impl.jac` annexes

no dict fields on any node/edge. `main.jac` keeps exporting `register_team`, `add_judge`, `assign`, `score`, `team_score`, `leaderboard`, `pending` — same signatures, same results and status strings; the scoring app imports from `main` and I don't want to touch it.
