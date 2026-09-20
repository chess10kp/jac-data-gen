"""Extension plane declaration consolidation lineage probes.
Provenance: matdev83/go-llm-interactive-proxy#451
"""

node Issue {
    has iid: str;
    has open: bool = True;
    has tasks_left: list[str] = [];
}

edge Depends {}

walker IssueLookupWalker {
    has target_id: str = "";
    has found: Issue | None = None;
    has claimed: dict[str, bool] = {};

    can seek with Issue entry {
        if here.iid in self.claimed {
            skip;
        }
        self.claimed[here.iid] = True;
        print(["seek", here.iid, self.target_id]);
        if here.iid == self.target_id {
            self.found = here;
            disengage;
        }
        nbrs: list[Issue] = [];
        for n in [here ->>][?:Issue] {
            nbrs.append(n);
        }
        if nbrs {
            visit nbrs;
        } else {
            disengage;
        }
    }
}

walker DownstreamWalker {
    has start_id: str = "";
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can descend with Issue entry {
        if here.iid in self.claimed {
            skip;
        }
        self.claimed[here.iid] = True;
        print(["downstream", here.iid]);
        if here.iid != self.start_id {
            self.found.append(here.iid);
        }
        kids: list[Issue] = [];
        for ch in [here ->:Depends:->][?:Issue] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker UpstreamWalker {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can ascend with Issue entry {
        if here.iid in self.claimed {
            skip;
        }
        self.claimed[here.iid] = True;
        print(["upstream", here.iid]);
        preds: list[Issue] = [];
        for p in [here <-:Depends:<-][?:Issue] {
            preds.append(p);
        }
        if preds {
            visit :0: preds;
            for p in preds {
                self.chain.append(p.iid);
            }
        } else {
            disengage;
        }
    }
}

def lookup_issue(graph_anchor: Issue, issue_id: str) -> Issue | None {
    wk = graph_anchor spawn IssueLookupWalker(target_id=issue_id);
    return wk.found;
}

def build_consolidation_graph -> Issue {
    graph_anchor = Issue(iid="anchor");
    i451 = Issue(iid="451", open=True, tasks_left=["10.1", "10.2", "10.3"]);
    i532 = Issue(iid="532", open=True);
    i503 = Issue(iid="503", open=True);
    i398 = Issue(iid="398", open=True);
    i394 = Issue(iid="394", open=True);
    graph_anchor ++> i451;
    graph_anchor ++> i394;
    i451 +>:Depends:+> i532;
    i532 +>:Depends:+> i503;
    i503 +>:Depends:+> i398;
    return graph_anchor;
}

def build_diamond_graph -> Issue {
    graph_anchor = Issue(iid="anchor");
    ia = Issue(iid="a");
    ib = Issue(iid="b");
    ic = Issue(iid="c");
    node_d = Issue(iid="d");
    graph_anchor ++> ia;
    ia +>:Depends:+> ib;
    ia +>:Depends:+> ic;
    ib +>:Depends:+> node_d;
    ic +>:Depends:+> node_d;
    return graph_anchor;
}

def dependency_successors(issue_id: str) -> list[str] {
    g = build_consolidation_graph();
    node = lookup_issue(g, issue_id);
    if node is None {
        return [];
    }
    out: list[str] = [];
    for ch in [node ->:Depends:->][?:Issue] {
        out.append(ch.iid);
    }
    return sorted(out);
}

def reachable_downstream(start_id: str) -> list[str] {
    g = build_consolidation_graph();
    start = lookup_issue(g, start_id);
    if start is None {
        return [];
    }
    wk = start spawn DownstreamWalker(start_id=start_id);
    return sorted(wk.found);
}

def diamond_downstream(start_id: str) -> list[str] {
    g = build_diamond_graph();
    start = lookup_issue(g, start_id);
    if start is None {
        return [];
    }
    wk = start spawn DownstreamWalker(start_id=start_id);
    return sorted(wk.found);
}

def prerequisite_chain(target_id: str) -> list[str] {
    g = build_consolidation_graph();
    target = lookup_issue(g, target_id);
    if target is None {
        return [];
    }
    wk = target spawn UpstreamWalker;
    print(wk.chain);
    return wk.chain;
}

def remaining_certification_tasks(issue_id: str) -> list[str] {
    g = build_consolidation_graph();
    node = lookup_issue(g, issue_id);
    if node is None {
        return [];
    }
    return node.tasks_left;
}

def on_certification_path(issue_id: str) -> bool {
    g = build_consolidation_graph();
    node = lookup_issue(g, issue_id);
    if node is None {
        return False;
    }
    if issue_id == "394" {
        return False;
    }
    chain = prerequisite_chain("398");
    if issue_id == "398" {
        return True;
    }
    in_chain = False;
    for cid in chain {
        if cid == issue_id {
            in_chain = True;
        }
    }
    if in_chain {
        return True;
    }
    if issue_id == "451" {
        return True;
    }
    return False;
}

"""Extension plane declaration consolidation lineage probes.
Provenance: matdev83/go-llm-interactive-proxy#451
"""

node Issue {
    has iid: str;
    has open: bool = True;
    has tasks_left: list[str] = [];
}

edge Depends {}

walker IssueLookupWalker {
    has target_id: str = "";
    has found: Issue | None = None;
    has claimed: dict[str, bool] = {};

    can seek with Issue entry {
        if here.iid in self.claimed {
            skip;
        }
        self.claimed[here.iid] = True;
        print(["seek", here.iid, self.target_id]);
        if here.iid == self.target_id {
            self.found = here;
            disengage;
        }
        nbrs: list[Issue] = [];
        for n in [here ->>][?:Issue] {
            nbrs.append(n);
        }
        if nbrs {
            visit nbrs;
        } else {
            disengage;
        }
    }
}

walker DownstreamWalker {
    has start_id: str = "";
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can descend with Issue entry {
        if here.iid in self.claimed {
            skip;
        }
        self.claimed[here.iid] = True;
        print(["downstream", here.iid]);
        if here.iid != self.start_id {
            self.found.append(here.iid);
        }
        kids: list[Issue] = [];
        for ch in [here ->:Depends:->][?:Issue] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker UpstreamWalker {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can ascend with Issue entry {
        if here.iid in self.claimed {
            skip;
        }
        self.claimed[here.iid] = True;
        print(["upstream", here.iid]);
        preds: list[Issue] = [];
        for p in [here <-:Depends:<-][?:Issue] {
            preds.append(p);
        }
        if preds {
            visit :0: preds;
            for p in preds {
                self.chain.append(p.iid);
            }
        } else {
            disengage;
        }
    }
}

def lookup_issue(graph_anchor: Issue, issue_id: str) -> Issue | None {
    wk = graph_anchor spawn IssueLookupWalker(target_id=issue_id);
    return wk.found;
}

def build_consolidation_graph -> Issue {
    graph_anchor = Issue(iid="anchor");
    i451 = Issue(iid="451", open=True, tasks_left=["10.1", "10.2", "10.3"]);
    i532 = Issue(iid="532", open=True);
    i503 = Issue(iid="503", open=True);
    i398 = Issue(iid="398", open=True);
    i394 = Issue(iid="394", open=True);
    graph_anchor ++> i451;
    graph_anchor ++> i394;
    i451 +>:Depends:+> i532;
    i532 +>:Depends:+> i503;
    i503 +>:Depends:+> i398;
    return graph_anchor;
}

def build_diamond_graph -> Issue {
    graph_anchor = Issue(iid="anchor");
    ia = Issue(iid="a");
    ib = Issue(iid="b");
    ic = Issue(iid="c");
    node_d = Issue(iid="d");
    graph_anchor ++> ia;
    ia +>:Depends:+> ib;
    ia +>:Depends:+> ic;
    ib +>:Depends:+> node_d;
    ic +>:Depends:+> node_d;
    return graph_anchor;
}

def dependency_successors(issue_id: str) -> list[str] {
    g = build_consolidation_graph();
    node = lookup_issue(g, issue_id);
    if node is None {
        return [];
    }
    out: list[str] = [];
    for ch in [node ->:Depends:->][?:Issue] {
        out.append(ch.iid);
    }
    return sorted(out);
}

def reachable_downstream(start_id: str) -> list[str] {
    g = build_consolidation_graph();
    start = lookup_issue(g, start_id);
    if start is None {
        return [];
    }
    wk = start spawn DownstreamWalker(start_id=start_id);
    return sorted(wk.found);
}

def diamond_downstream(start_id: str) -> list[str] {
    g = build_diamond_graph();
    start = lookup_issue(g, start_id);
    if start is None {
        return [];
    }
    wk = start spawn DownstreamWalker(start_id=start_id);
    return sorted(wk.found);
}

def prerequisite_chain(target_id: str) -> list[str] {
    g = build_consolidation_graph();
    target = lookup_issue(g, target_id);
    if target is None {
        return [];
    }
    wk = target spawn UpstreamWalker;
    print(wk.chain);
    return wk.chain;
}

def remaining_certification_tasks(issue_id: str) -> list[str] {
    g = build_consolidation_graph();
    node = lookup_issue(g, issue_id);
    if node is None {
        return [];
    }
    return node.tasks_left;
}

def on_certification_path(issue_id: str) -> bool {
    g = build_consolidation_graph();
    node = lookup_issue(g, issue_id);
    if node is None {
        return False;
    }
    if issue_id == "394" {
        return False;
    }
    chain = prerequisite_chain("398");
    if issue_id == "398" {
        return True;
    }
    in_chain = False;
    for cid in chain {
        if cid == issue_id {
            in_chain = True;
        }
    }
    if in_chain {
        return True;
    }
    if issue_id == "451" {
        return True;
    }
    return False;
}

test "dependency_successors_direct" {
    assert dependency_successors("451") == ["532"];
}

test "reachable_downstream_closure" {
    assert reachable_downstream("451") == ["398", "503", "532"];
}

test "prerequisite_chain_upstream" {
    assert prerequisite_chain("398") == ["503", "532", "451"];
}

test "diamond_downstream_sorted" {
    assert diamond_downstream("a") == ["b", "c", "d"];
}

test "remaining_certification_tasks" {
    assert remaining_certification_tasks("451") == ["10.1", "10.2", "10.3"];
}

test "on_certification_path_flags" {
    assert on_certification_path("398") == True;
    assert on_certification_path("394") == False;
    assert on_certification_path("451") == True;
    assert on_certification_path("missing") == False;
}
