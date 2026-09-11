"""amichne/kast#570 — public tooling delivery issue dependency graph."""

class CycleError(Exception) {}

node Issue {
    has iid: str;
}

edge BlockedBy {}

edge ChildOf {}

obj IssueGraph {
    has issues: dict[str, Issue] = {};
}

walker UnblockReach {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Issue entry {
        if here.iid in self.claimed { skip; }
        self.claimed[here.iid] = True;
        self.reached.append(here.iid);
        visit [<-:BlockedBy:<-][?:Issue];
    }
}

def load_issue_graph(
    issue_ids: list[str],
    blocked_edges: list[tuple[str, str]],
    parent_links: list[tuple[str, str | None]],
) -> IssueGraph {
    g = IssueGraph();
    for iid in issue_ids {
        nd = Issue(iid=iid);
        root ++> nd;
        g.issues[iid] = nd;
    }
    for (blocker, blocked) in blocked_edges {
        b = g.issues.get(blocker, None);
        d = g.issues.get(blocked, None);
        if b is not None and d is not None { d +>:BlockedBy:+> b; }
    }
    for (iid, parent) in parent_links {
        if iid in g.issues {
            if parent is not None {
                p = g.issues.get(parent, None);
                if p is not None { p +>:ChildOf:+> g.issues[iid]; }
            }
        }
    }
    return g;
}

def dependency_levels(g: IssueGraph) -> list[list[str]] {
    indegree: dict[str, int] = {};
    rev: dict[str, list[str]] = {};
    for iid in g.issues {
        indegree[iid] = 0;
        rev[iid] = [];
    }
    for iid in g.issues {
        nd = g.issues[iid];
        for blk in [nd ->:BlockedBy:->][?:Issue] {
            indegree[iid] += 1;
            rev[blk.iid].append(iid);
        }
    }
    layers: list[list[str]] = [];
    visited: dict[str, bool] = {};
    ready: dict[str, bool] = {};
    for iid in g.issues {
        if indegree[iid] == 0 { ready[iid] = True; }
    }
    while len(ready) > 0 {
        layer = sorted([i for i in ready.keys()]);
        layers.append(layer);
        next_ready: dict[str, bool] = {};
        for node in layer {
            visited[node] = True;
            for other in rev.get(node, []) {
                indegree[other] -= 1;
                if indegree[other] == 0 and not (other in visited) {
                    next_ready[other] = True;
                }
            }
        }
        ready = next_ready;
    }
    if len(visited) != len(g.issues) {
        raise CycleError("blocked-by cycle");
    }
    return layers;
}

def ready_frontier(g: IssueGraph, completed: list[str]) -> list[str] {
    done: dict[str, bool] = {};
    for c in completed { done[c] = True; }
    layers = dependency_levels(g);
    for layer in layers {
        frontier: list[str] = [];
        for i in layer {
            if not (i in done) { frontier.append(i); }
        }
        if len(frontier) > 0 { return sorted(frontier); }
    }
    return [];
}

def child_issues(g: IssueGraph, parent: str) -> list[str] {
    out: list[str] = [];
    for iid in sorted(g.issues.keys()) {
        nd = g.issues.get(iid, None);
        if nd is None { continue; }
        for p in [nd <-:ChildOf:<-][?:Issue] {
            if p.iid == parent { out.append(iid); }
        }
    }
    return out;
}

def unblock_reach(g: IssueGraph, `root: str) -> list[str] {
    nd = g.issues.get(`root, None);
    if nd is None { return []; }
    w = nd spawn UnblockReach(claimed={}, reached=[]);
    out: list[str] = [];
    for iid in w.reached {
        if iid != `root { out.append(iid); }
    }
    return sorted(out);
}
