"""RL driver (guestbook): guestbook.explore_graph.walk_day.

Origin: this_is_jac/guestbook.jac. `explore_graph` walks the live graph
root -> Day -> Visitor, recording the visit order, the node views, the edges,
and a human log. The marked body is `walk_day` (Day entry): it records the Day
node, the root->day edge, the path step, the log line, then descends to the
day's visitors.

To keep stdout deterministic (the runtime auto-prints the report, which would
otherwise embed random jids), this inlined copy identifies nodes by stable keys
(self.rid='root', the Day's date, the Visitor's name) instead of jid(...), and
walks `root` instead of `root.shared` so it runs under plain `jac run`.
"""

obj GraphNodeView { has id: str, label: str, kind: str; }
obj GraphSnapshot {
    has nodes: list[GraphNodeView], edges: list[list[str]],
        path: list[str], log: list[str];
}

edge OnDay {}
edge Signed {}

node Day { has date: str = ""; }
node Visitor {
    has name: str = "", message: str = "", created_at: str = "";
}

walker explore_graph {
    has rid: str = "",
        nodes: list[GraphNodeView] = [],
        edges: list[list[str]] = [],
        path: list[str] = [],
        log: list[str] = [],
        reports: list[GraphSnapshot] = [];

    can run with Root entry {
        self.rid = "root";
        self.nodes.append(GraphNodeView(id=self.rid, label="root", kind="root"));
        self.path.append(self.rid);
        self.log.append("walker spawned at the shared root");
        visit [root-->[?:Day]];
    }

    can walk_day with Day entry {
        # >>>HOLE id="gb_explore_graph_walk_day" instruction="Implement the walk_day ability (walker explore_graph, on Day entry). Let did = here.date. Append a GraphNodeView with id=did, label=here.date, kind set to the literal day, to self.nodes. Append the edge [self.rid, did] to self.edges. Append did to self.path. Append the log line 'entered ' concatenated with here.date to self.log. Then visit the day's Visitors via [-->[?:Visitor]]."
        did = here.date;
        self.nodes.append(GraphNodeView(id=did, label=here.date, kind="day"));
        self.edges.append([self.rid, did]);
        self.path.append(did);
        self.log.append("entered " + here.date);
        visit [-->[?:Visitor]];
        # <<<HOLE
    }

    can walk with Visitor entry {
        vid = here.name;
        parents = [here<--[?:Day]];
        did = parents[0].date if parents else self.rid;
        self.nodes.append(GraphNodeView(id=vid, label=here.name, kind="visitor"));
        self.edges.append([did, vid]);
        self.path.append(vid);
        self.log.append("visited " + here.name);
    }

    can deliver with Root exit {
        self.log.append("traversal complete: " + str(len(self.nodes)) + " nodes");
        report GraphSnapshot(nodes=self.nodes, edges=self.edges, path=self.path, log=self.log);
    }
}

with entry {
    d = (root +>: OnDay() :+> Day(date="2020-01-01"))[0];
    d +>: Signed() :+> Visitor(name="alice", message="hi");
    d +>: Signed() :+> Visitor(name="bob", message="yo");
    res = root spawn explore_graph();
    snap = res.reports[0];
    print("node_count:", len(snap.nodes));
    print("edge_count:", len(snap.edges));
    print("path_len:", len(snap.path));
    print("kinds:", [n.kind for n in snap.nodes]);
    print("labels:", [n.label for n in snap.nodes]);
    print("log:", snap.log);
}
