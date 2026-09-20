"""Stewie-pixel/claude-with-leetcode#157 — Maximum Path Quality of a Graph."""

node PQNode {
    has idx: int = 0;
    has node_val: int = 0;
}

edge PQEdge {
    has cost: int = 0;
}

walker PQSearch {
    has max_time: int = 0;
    has time_used: int = 0;
    has collected: int = 0;
    has best: int = 0;
    has start_cid: str = "";
    has visits: dict[str, int] = {};
    has claimed: dict[str, bool] = {};

    can dfs with PQNode entry {
        if here.cid == self.start_cid {
            if self.collected > self.best {
                self.best = self.collected;
            }
        }
        outs: list = [here ->:PQEdge->];
        for ed in outs {
            nxt_list: list[PQNode] = [ed ->:PQNode:->];
            if len(nxt_list) == 0 {
                continue;
            }
            nb = nxt_list[0];
            ecost = ed.cost;
            nt = self.time_used + ecost;
            if nt > self.max_time {
                continue;
            }
            cid = nb.cid;
            prev: int = 0;
            if cid in self.visits {
                prev = self.visits[cid];
            }
            add: int = 0;
            if prev == 0 {
                add = nb.node_val;
            }
            self.visits[cid] = prev + 1;
            saved_t = self.time_used;
            saved_c = self.collected;
            self.time_used = nt;
            self.collected = self.collected + add;
            if cid in self.claimed {
                skip;
            }
            self.claimed[cid] = True;
            visit :0: [nb];
            if cid in self.claimed {
                del self.claimed[cid];
            }
            self.visits[cid] = prev;
            self.time_used = saved_t;
            self.collected = saved_c;
        }
        print self.best;
        disengage;
    }
}

def maximalPathQuality(values: list, edges: list, maxTime: int) -> int {
    by_idx: dict[int, PQNode] = {};
    i: int = 0;
    while i < len(values) {
        nd = PQNode(idx=i, node_val=values[i]);
        root ++> nd;
        by_idx[i] = nd;
        i += 1;
    }
    graph_root: PQNode = by_idx[0];
    for e in edges {
        u = e[0];
        v = e[1];
        t = e[2];
        a = by_idx[u];
        b = by_idx[v];
        a +>:PQEdge(cost=t):+> b;
        b +>:PQEdge(cost=t):+> a;
    }
    init_vis: dict[str, int] = {};
    init_vis[graph_root.cid] = 1;
    w = graph_root spawn PQSearch(
        max_time=maxTime,
        start_cid=graph_root.cid,
        collected=values[0],
        visits=init_vis
    );
    return w.best;
}
