`ladder.jac` has grown into one big Python-style module: all state lives in a `LadderBook` node (found with an `isinstance` scan over root) holding a name->rank dict and a list of match dicts, outcomes are bare strings, and every function loops over those dicts.

I'd like it rebuilt as a proper graph:

- players as nodes on root, and each recorded match as a typed edge from challenger to defender that carries the outcome and the round
- the outcome as an enum rather than "win"/"loss"/"draw" strings (callers still pass those strings in)
- walkers doing the real work: at least one for validating/recording a challenge and one for tallying a player's results (head-to-head can reuse the tally); use edge filters for the lookups instead of dict scans
- split declarations from implementations: `ladder.jac` should read as the interface (enum, nodes, edge, walkers with their ability signatures, function signatures) and every function and ability body moves into a `ladder.impl.jac` annex next to it

Public surface stays exactly as it is: the module path `ladder` and the functions `join`, `standings`, `challenge`, `record`, `head_to_head`, `withdraw` and `active_since`, with the same arguments, return values and error strings.
