# ref-l3-orienteering-course
Smell: Python `class` with init and dict/tuple adjacency + manual BFS queue.
Target: Course as a node owning Control nodes; typed Leg edge (Control --> Control) with metres; a walker (Sweep) doing reachability/points; edge-object read for longest leg.
Idiom targets: no class, >=2 node types, >=1 edge type, >=1 walker, >=1 visit, >=1 spawn, 0 dict fields, >=1 edge filter.
Each Course is a transient subgraph (not on root) so two courses stay separate; test "two courses" pins that.
