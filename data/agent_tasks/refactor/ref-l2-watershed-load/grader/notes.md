# ref-l2-watershed-load
Smell: pure functions over input records that build an adjacency dict (`_feeders`: dict[str, list[str]]) and run a hand-written while/stack traversal; the dry-season rule is baked into the dict build.
Target: each call builds a throwaway graph (Reach nodes + FlowsInto typed edge with `seasonal`), spawns an Upstream walker on the gauge reach that climbs incoming FlowsInto edges (edge predicate `seasonal == False` in the dry season); headwaters = reaches with no incoming FlowsInto.
Idiom targets: >=1 node, >=1 edge, >=1 walker, >=1 visit, >=1 spawn, >=1 edge filter.
Loads are exact binary fractions and summed with math.fsum, so traversal order cannot change results.
Codespace (jac 0.36.1): the module "preferred native but did not lower" (E5092 on builtin `float`) and compiles server for both starter and reference. `import math` does NOT anchor it. Anchor-free modules that DO lower native segfault under `jac test` on graph code at 0.36.1 (seen on the orienteering pilot), which is why the other L2 tasks of this batch are root-backed.
The transient graph is never attached to root.
