# ref-l3-lifting-journal
Smell: obj with dict[str, list[dict[str, any]]] of raw set records, string kinds validated against a list field, every stat a fresh manual scan.
Target: Journal node facade owning Exercise + Session nodes; Trained edge (Exercise --> Session) aggregating volume/top/fails per session; SetKind enum; History walker spawned on an Exercise visiting its sessions and reading the edge via [edge self.ex ->:Trained:-> here]; incoming edge ref for trained_on.
Idiom targets: >=2 nodes, >=1 edge, >=1 walker, >=1 visit, >=1 enum, 0 dict fields, >=2 edge filters.
Weights in tests are binary-exact so float sums are order-independent (starter sums per set, reference per session).
jac.toml pins default_codespace = "server" (0.36.1 native seam crashes jac test).
