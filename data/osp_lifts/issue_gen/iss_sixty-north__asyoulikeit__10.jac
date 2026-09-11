"""GraphContent lifted to OSP (sixty-north/asyoulikeit#10).

The adjacency bookkeeping dies: report nodes become ``GNode`` archetypes,
call edges become typed ``Call`` edges carrying their instruction type as a
payload, and the DOT renderer reads neighbours and edge attributes straight
off the typed topology instead of rescanning an edge list per node.
Successors come back sorted so the rendered graph is byte-deterministic;
the issue's attribute conventions survive (external nodes dashed/gray,
jmp edges dashed).
"""

node GNode {
    has nid: str;
    has label: str;
    has external: bool = False;
}

# the instruction kind IS the semantic edge distinction: two typed edges
edge JsrCall: GNode --> GNode {}

edge JmpCall: GNode --> GNode {}

glob g_nodes: dict[str, GNode] = {};

glob g_title: str = "callgraph";

glob g_directed: bool = True;


def graph_init(title: str = "callgraph", directed: bool = True) -> None {
    # fresh report lifecycle; also lets guards reset deterministically
    for k in list(g_nodes.keys()) {
        old = g_nodes[k];
        del old;
        g_nodes.pop(k, None);
    }
    g_title = title;
    g_directed = directed;
}


def add_node(nid: str, name: str | None = None, external: bool = False) -> None {
    if nid in g_nodes {
        raise ValueError("duplicate node");
    }
    root ++> (n := GNode(nid=nid, label=name or nid, external=external));
    g_nodes[nid] = n;
}


def add_edge(src: str, dst: str, etype: str = "jsr") -> None {
    if src not in g_nodes or dst not in g_nodes {
        raise KeyError(src);
    }
    if etype not in ("jsr", "jmp") {
        raise ValueError(etype);
    }
    if etype == "jmp" {
        g_nodes[src] +>:JmpCall:+> g_nodes[dst];
    } else {
        g_nodes[src] +>:JsrCall:+> g_nodes[dst];
    }
}


def successors(nid: str) -> list[str] {
    names: set[str] = set();
    for d in [g_nodes[nid] ->:JsrCall:->] {
        names.add(d.nid);
    }
    for d in [g_nodes[nid] ->:JmpCall:->] {
        names.add(d.nid);
    }
    return sorted(names);
}


walker ReachWalk {
    """Claims each node once; revisits are skipped, not disengaged on."""
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can go with GNode entry {
        if here.nid in self.claimed {
            return;
        }
        self.claimed[here.nid] = True;
        self.found.append(here.nid);
        nbrs = [here ->:JsrCall:->];
        nbrs.extend([here ->:JmpCall:->]);
        for nxt in nbrs {
            sub = ReachWalk(claimed=self.claimed);
            nxt spawn sub;
            self.found.extend(sub.found);
        }
    }
}


def reachable(start: str) -> list[str] {
    w = g_nodes[start] spawn ReachWalk(claimed={});
    return sorted(set(w.found));
}


def _q(label: str) -> str {
    out = label.replace("\\", "\\\\").replace("\"", "\\\"");
    return "\"" + out + "\"";
}


def to_dot() -> str {
    lines: list[str] = ["digraph " + _q(g_title) + " {"];
    for nid in sorted(g_nodes.keys()) {
        meta = g_nodes[nid];
        attrs = ["label=" + _q(meta.label)];
        if meta.external {
            attrs.append("style=dashed");
            attrs.append("color=gray");
        }
        lines.append("  {} [{}];".format(_q(nid), ", ".join(attrs)));
    }
    pairs: list[tuple] = [];
    for nid in sorted(g_nodes.keys()) {
        for d in [g_nodes[nid] ->:JsrCall:->] {
            pairs.append((nid, d.nid, "jsr"));
        }
        for d in [g_nodes[nid] ->:JmpCall:->] {
            pairs.append((nid, d.nid, "jmp"));
        }
    }
    for trip in sorted(pairs) {
        s = trip[0];
        d = trip[1];
        et = trip[2];
        suffix = " [style=dashed]" if et == "jmp" else "";
        arrow = "->" if g_directed else "--";
        lines.append("  {} {} {}{};".format(_q(s), arrow, _q(d), suffix));
    }
    lines.append("}");
    return "\n".join(lines) + "\n";
}
