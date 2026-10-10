# nat-l4-chess-ladder
New module required by an existing main.jac entry (run gate replays the season demo). Rank shifting keeps 1..N gap-free; edge history both directions.
Demo: Eli(5) beats Ben(2) -> Ada,Eli,Ben,Cyd,Dov; Dov(5) loses to Cyd(4) (recorded); Dov vs Ada gap 4 rejected; h2h dov-cyd 0-1.
Alternative: node-visiting shift, rank->name dict standings, h2h via outgoing edges of both players.
- Quirk: hidden tests that did `[player(n) ->:Played:->]` with `player()` returning `Player | None` were rejected (E1137) when `jac test` ran in a fresh workspace, but passed when `jac check` had run first in the same workspace -> test-module type checking is cache-order dependent. Tests now use a non-optional helper.
