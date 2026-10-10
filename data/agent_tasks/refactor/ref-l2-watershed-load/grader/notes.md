# ref-l2-watershed-load
Smell: pure functions over input records that build an adjacency dict (`_feeders`: dict[str, list[str]]) and run a hand-written while/stack traversal; the dry-season rule is baked into the dict build.
Target: each call builds a throwaway graph (Reach nodes + FlowsInto typed edge with `seasonal`), spawns an Upstream walker on the gauge reach that climbs incoming FlowsInto edges (edge predicate `seasonal == False` in the dry season); headwaters = reaches with no incoming FlowsInto.
Idiom targets: >=1 node, >=1 edge, >=1 walker, >=1 visit, >=1 spawn, >=1 edge filter.
Loads are exact binary fractions and summed with math.fsum, so traversal order cannot change results.
Codespace: starter/ and reference/ carry jac.toml `[build] default_codespace = "server"` (at jac 0.36.1 native-compiled modules can SIGSEGV/SIGABRT under `jac test`; without it this module only stayed server because `float()` fails native lowering, E5092). `import math` does NOT anchor server.
The transient graph is never attached to root.
