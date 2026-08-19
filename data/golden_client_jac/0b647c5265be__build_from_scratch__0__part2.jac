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
        did = here.date;
        self.nodes.append(GraphNodeView(id=did, label=here.date, kind="day"));
        self.edges.append([self.rid, did]);
        self.path.append(did);
        self.log.append("entered " + here.date);
        visit [-->[?:Visitor]];
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
