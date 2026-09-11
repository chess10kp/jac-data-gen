"""flyingrobots/method#72 — GitHub issue dependency graph for Method."""

node Issue {
    has iid: int;
    has open: bool = True;
}

edge DependsOn {}

obj IssueGraph {
    has issues: dict[int, Issue] = {};
}

walker CycleProbe {
    has visited: dict[int, bool] = {};
    has stack: dict[int, bool] = {};
    has errors: list[tuple[int, int]] = [];

    can step with Issue entry {
        if here.iid in self.visited { skip; }
        self.visited[here.iid] = True;
        self.stack[here.iid] = True;
        for dep in [here ->:DependsOn:->][?:Issue] {
            if dep.iid in self.stack {
                self.errors.append((here.iid, dep.iid));
            } else {
                if not (dep.iid in self.visited) { visit [dep]; }
            }
        }
        self.stack[here.iid] = False;
    }
}

def load_issue_graph(
    issue_ids: list[int],
    depends_edges: list[tuple[int, int]],
    open_issues: list[int] | None = None,
) -> IssueGraph {
    g = IssueGraph();
    for iid in issue_ids {
        nd = Issue(iid=iid);
        root ++> nd;
        g.issues[iid] = nd;
    }
    if open_issues is None {
        for iid in issue_ids { g.issues[iid].open = True; }
    } else {
        for iid in issue_ids {
            g.issues[iid].open = iid in open_issues;
        }
    }
    for (blocker, blocked) in depends_edges {
        b = g.issues.get(blocker, None);
        d = g.issues.get(blocked, None);
        if b is not None and d is not None { d +>:DependsOn:+> b; }
    }
    return g;
}

def _unresolved_blockers(store: IssueGraph, issue: int) -> list[int] {
    nd = store.issues.get(issue, None);
    if nd is None { return []; }
    out: list[int] = [];
    for dep in [nd ->:DependsOn:->][?:Issue] {
        if dep.open { out.append(dep.iid); }
    }
    return sorted(out);
}

def frontier_issues(store: IssueGraph) -> list[int] {
    out: list[int] = [];
    for iid in sorted(store.issues.keys()) {
        nd = store.issues.get(iid, None);
        if nd is None or not nd.open { continue; }
        if len(_unresolved_blockers(store, iid)) == 0 { out.append(iid); }
    }
    return out;
}

def detect_dependency_cycles(store: IssueGraph) -> list[tuple[int, int]] {
    errors: list[tuple[int, int]] = [];
    visited: dict[int, bool] = {};
    for k in sorted(store.issues.keys()) {
        if k in visited { continue; }
        nd = store.issues[k];
        w = nd spawn CycleProbe(visited=visited, stack={}, errors=[]);
        errors = errors + w.errors;
        visited = w.visited;
    }
    return sorted(errors);
}

def critical_path_depth(store: IssueGraph, issue: int) -> int {
    nd = store.issues.get(issue, None);
    if nd is None { return -1; }
    depth: dict[int, int] = {issue: 0};
    frontier: list[Issue] = [nd];
    best = 0;
    while len(frontier) > 0 {
        cur = frontier.pop(0);
        cur_depth = depth[cur.iid];
        for dep in [cur ->:DependsOn:->][?:Issue] {
            nd2 = cur_depth + 1;
            if nd2 > best { best = nd2; }
            if not (dep.iid in depth) or nd2 > depth[dep.iid] {
                depth[dep.iid] = nd2;
                frontier.append(dep);
            }
        }
    }
    return best;
}
