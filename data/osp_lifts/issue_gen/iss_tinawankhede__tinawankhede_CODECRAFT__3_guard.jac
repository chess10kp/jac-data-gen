"""tinawankhede/tinawankhede_CODECRAFT#3 — DFS on an adjacency-list graph."""

node Vertex {
    has vid: str;
    has nbr_ids: list[str] = [];
}

edge Link {}

walker DfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has node_map: dict[str, Vertex] = {};

    can step with Vertex entry {
        if here.vid in self.claimed {
            skip;
        }
        self.claimed[here.vid] = True;
        self.order.append(here.vid);
        print(here.vid);
        kids: list[Vertex] = [];
        for nb_id in here.nbr_ids {
            if nb_id in self.node_map {
                ch = self.node_map[nb_id];
                kids.append(ch);
            }
        }
        rev: list[Vertex] = [];
        idx = len(kids) - 1;
        while idx >= 0 {
            rev.append(kids[idx]);
            idx = idx - 1;
        }
        visit :0: rev else {
            disengage;
        }
    }
}

walker BootWalker {
    can boot with Vertex entry {
        sample: dict[str, list[str]] = {
            "A": ["B", "C"],
            "B": ["A", "D", "E"],
            "C": ["A", "F"],
            "D": ["B"],
            "E": ["B", "F"],
            "F": ["C", "E"],
        };
        print("Depth-First Search starting from vertex A:");
        dfs(sample, "A");
        disengage;
    }
}

def build_node_map(adj: dict[str, list[str]]) -> dict[str, Vertex] {
    nodes: dict[str, Vertex] = {};
    keys: list[str] = sorted(adj.keys());
    for k in keys {
        if k not in nodes {
            nbrs: list[str] = adj[k];
            nd = Vertex(vid=k, nbr_ids=nbrs);
            root ++> nd;
            nodes[k] = nd;
        }
    }
    for k in keys {
        nbr_list: list[str] = adj[k];
        for nb in nbr_list {
            if nb not in nodes {
                empty: list[str] = [];
                if nb in adj {
                    empty = adj[nb];
                }
                nd2 = Vertex(vid=nb, nbr_ids=empty);
                root ++> nd2;
                nodes[nb] = nd2;
            }
        }
    }
    for k in keys {
        src = nodes[k];
        dst_ids: list[str] = adj[k];
        for dst_id in dst_ids {
            if dst_id in nodes {
                dst = nodes[dst_id];
                src +>:Link:+> dst;
            }
        }
    }
    return nodes;
}

def dfs(
    graph: dict[str, list[str]],
    start: str,
    visited: dict[str, bool] | None = None,
) -> list[str] {
    nodes = build_node_map(graph);
    if start not in nodes {
        return [];
    }
    seed: dict[str, bool] = {};
    if visited is not None {
        for vk in visited {
            seed[vk] = visited[vk];
        }
    }
    start_nd = nodes[start];
    w = start_nd spawn DfsWalker(claimed=seed, node_map=nodes, order=[]);
    if visited is not None {
        for ck in w.claimed {
            visited[ck] = w.claimed[ck];
        }
    }
    return w.order;
}

with entry {
    boot_nd = Vertex(vid="__boot__", nbr_ids=[]);
    root ++> boot_nd;
    wk = boot_nd spawn BootWalker;
}

test "dfs_sample_order" {
    sample: dict[str, list[str]] = {
        "A": ["B", "C"],
        "B": ["A", "D", "E"],
        "C": ["A", "F"],
        "D": ["B"],
        "E": ["B", "F"],
        "F": ["C", "E"],
    };
    got = dfs(sample, "A");
    exp: list[str] = ["A", "B", "D", "E", "F", "C"];
    assert len(got) == len(exp);
    idx = 0;
    while idx < len(exp) {
        assert got[idx] == exp[idx];
        idx = idx + 1;
    }
}

test "dfs_unknown_start" {
    got = dfs({}, "Z");
    assert len(got) == 0;
}

test "dfs_visited_mutation" {
    sample: dict[str, list[str]] = {"A": ["B"], "B": ["A"]};
    vis: dict[str, bool] = {};
    got = dfs(sample, "A", vis);
    assert len(got) == 2;
    assert vis["A"] == True;
    assert vis["B"] == True;
}

test "dfs_preclaimed_skips" {
    sample: dict[str, list[str]] = {"A": ["B"], "B": ["A"]};
    vis: dict[str, bool] = {"A": True};
    got = dfs(sample, "B", vis);
    assert len(got) == 1;
    assert got[0] == "B";
}

test "build_node_map_keys" {
    adj: dict[str, list[str]] = {"A": ["B"], "B": ["A"]};
    nodes = build_node_map(adj);
    assert "A" in nodes;
    assert "B" in nodes;
    assert nodes["A"].vid == "A";
}
