Our chess club runs a challenge ladder. The project already has `ladder.jac` (players on `root`, rank 1 = top, `join` adds someone at the bottom), `matches.jac` (the `Played` history edge and a `MatchResult` obj) and a `main.jac` season demo — but `main.jac` imports a `challenge` module that doesn't exist yet, so `jac run` fails. Please write `challenge.jac` with three walkers (all spawned on `root`):

**`RecordMatch(challenger, defender, challenger_won, round)`** — names of two players.
- If either player doesn't exist: report `MatchResult(ok=False, reason="unknown player")`.
- A challenge is only allowed **upwards** and at most **3 rungs** up: the defender's rank must be smaller than the challenger's, and `challenger.rank - defender.rank <= 3`. Otherwise report `MatchResult(ok=False, reason="out of range")` and record nothing.
- Valid matches are always recorded as a `Played` edge from challenger to defender (with `challenger_won` and `round`).
- If the challenger won, they take the defender's rank, and everybody from the defender's old rank down to just above the challenger's old rank moves down one rung. If the defender won, nothing changes.
- Report `MatchResult(ok=True, new_rank=<challenger's rank after the match>)`.

**`Standings()`** — report once the list of player names in rank order.

**`HeadToHead(a, b)`** — report once a dict `{a: wins of a against b, b: wins of b against a}` counting every recorded match between the two in either direction.

Ranks must always stay a gap-free 1..N. Please don't modify the other modules.
