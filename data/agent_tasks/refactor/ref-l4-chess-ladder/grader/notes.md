# ref-l4-chess-ladder
Smell: single module; `LadderBook` bucket node (isinstance scan) with `ranks: dict[str,int]` and `matches: list[dict]`; outcome as "win"/"loss"/"draw" strings; all bodies inline.
Target: `ladder.jac` = interface (enum Outcome, node Player, edge Played{outcome, round}, walkers RecordChallenge / Tally / Activity with ability decls, 8 function decls); `ladder.impl.jac` = 13 impl blocks.
Idiom targets: node>=1, edge>=1, walker>=2, enum>=1, edge_filters>=1, spawns>=2, dict_fields==0, isinstance==0, annex_impls>=6 (8 public functions alone give 8).
Behaviour notes: unknown-player check precedes outcome validation (same-name challenge = "unknown player"); draws/losses never move ranks; withdraw deletes the Player (cascading its Played edges) and closes the gap.
Quirk: `[here ->:Played:->]` returns each opponent once even with several edges, so Tally re-reads `[edge here ->:Played:-> opp]` per opponent.
Negatives: draw_moves_ranks, four_rungs_allowed, tally_ignores_defended, withdraw_leaves_gap (killed by the Dov->Ada range check), active_strictly_after.
jac 0.36.1: starter/ and reference/ carry jac.toml `[build] default_codespace = "server"` (native-lowered modules can SIGSEGV/SIGABRT under `jac test`). No lambdas: at 0.36.1 a typed block lambda used as a sort key failed at test time (`NameError: __jac_lambda_1`), so sorts use plain keys / str.lower.
