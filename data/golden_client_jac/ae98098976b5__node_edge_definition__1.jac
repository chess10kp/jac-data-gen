"""RL driver (pure-lib | graph): guestbook.explore_graph.deliver (append the node-count summary and report the snapshot).

Origin: this_is_jac/guestbook.jac (the explore_graph.deliver logic, isolated from any io/time/graph
machinery). Deterministic: nodes/edges/path/log are pre-filled with fixed literals (fixed string ids,
no jid, no time), so the appended 'traversal complete: N nodes' line is always 'traversal complete: 3
nodes'. The marked body is the unit the policy must regenerate; the with entry block exercises it on
fixed inputs and prints a deterministic projection.
"""

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
        # >>>HOLE id="gb_explore_graph_deliver" instruction="Implement the deliver ability (walker explore_graph, on Root exit). Append a log line to self.log built by concatenating 'traversal complete: ', the string form of the number of entries in self.nodes, and ' nodes'. Then report a GraphSnapshot built from self.nodes, self.edges, self.path and self.log."
        self.log.append("traversal complete: " + str(len(self.nodes)) + " nodes");
        report GraphSnapshot(
            nodes=self.nodes, edges=self.edges, path=self.path, log=self.log
        );
        # <<<HOLE
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
