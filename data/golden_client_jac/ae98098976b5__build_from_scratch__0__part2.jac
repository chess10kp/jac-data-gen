obj GraphNodeView { has id: str, label: str, kind: str; }
obj GraphSnapshot {
    has nodes: list[GraphNodeView], edges: list[list[str]],
        path: list[str], log: list[str];
}

walker explore_graph {
    has rid: str = "",
        nodes: list[GraphNodeView] = [],
        edges: list[list[str]] = [],
        path: list[str] = [],
        log: list[str] = [],
        reports: list[GraphSnapshot] = [];

    can deliver with Root exit {
        self.log.append("traversal complete: " + str(len(self.nodes)) + " nodes");
        report GraphSnapshot(
            nodes=self.nodes, edges=self.edges, path=self.path, log=self.log
        );
    }
}

with entry {
    nodes = [
        GraphNodeView(id="r0", label="root", kind="root"),
        GraphNodeView(id="d0", label="2026-01-01", kind="day"),
        GraphNodeView(id="v0", label="visitor", kind="visitor")
    ];
    edges = [["r0", "d0"], ["d0", "v0"]];
    path = ["r0", "d0", "v0"];
    log = ["walker spawned at the shared root", "entered 2026-01-01"];
    w = root spawn explore_graph(nodes=nodes, edges=edges, path=path, log=log);
    print(" | ".join(w.log));
}
