"""yevheniidehtiar/gitpm#223 cross-reference resolver and dependency graph."""

node Story { has sid: str; has epic_ref: str; }
node Epic { has eid: str; has milestone_ref: str; }
node Milestone { has mid: str; has roadmap_ref: str = ""; }
node Roadmap { has rid: str; }
node DepNode { has nid: str; }

edge StoryEpic {}
edge EpicMilestone {}
edge MilestoneRoadmap {}
edge Depends {}

walker ChainWalker {
    has claimed: dict[str, bool] = {};
    has result: dict[str, str | None] = {"story": None, "epic": None, "milestone": None, "roadmap": None};

    can step_story with Story entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.result["story"] = here.sid;
        print(["story", here.sid]);
        nxt: list[Epic] = [here ->:StoryEpic:->][?:Epic];
        if nxt { visit :0: nxt; } else { disengage; }
    }

    can step_epic with Epic entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        self.result["epic"] = here.eid;
        print(["epic", here.eid]);
        nxt: list[Milestone] = [here ->:EpicMilestone:->][?:Milestone];
        if nxt { visit :0: nxt; } else { disengage; }
    }

    can step_milestone with Milestone entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        self.result["milestone"] = here.mid;
        print(["milestone", here.mid]);
        nxt: list[Roadmap] = [here ->:MilestoneRoadmap:->][?:Roadmap];
        if nxt { visit :0: nxt; } else { disengage; }
    }

    can step_roadmap with Roadmap entry {
        if here.rid in self.claimed { skip; }
        self.claimed[here.rid] = True;
        self.result["roadmap"] = here.rid;
        print(["roadmap", here.rid]);
        disengage;
    }
}

walker DepWalk {
    has claimed: dict[str, bool] = {};
    has on_stack: dict[str, bool] = {};
    has order: list[str] = [];
    has cyclic: bool = False;

    can step with DepNode entry {
        if here.nid in self.on_stack { self.cyclic = True; skip; }
        if here.nid in self.claimed { skip; }
        self.on_stack[here.nid] = True;
        kids: list[DepNode] = [here ->:Depends:->][?:DepNode];
        for k in kids { visit :0: [k]; }
        self.on_stack[here.nid] = False;
        self.claimed[here.nid] = True;
        self.order.append(here.nid);
        print([here.nid, self.cyclic]);
    }
}

def build_lookup_maps(
    stories: dict[str, str],
    epics: dict[str, str],
    roadmaps: dict[str, list[str]],
    prds: dict[str, list[str]],
) -> dict[str, object] {
    out: dict[str, object] = {};
    out["story_epic"] = stories;
    out["epic_milestone"] = epics;
    out["roadmap_milestones"] = roadmaps;
    out["prd_epics"] = prds;
    return out;
}

def resolve_story_chain(
    story_id: str,
    story_epic: dict[str, str],
    epic_milestone: dict[str, str],
    milestone_roadmap: dict[str, str],
) -> dict[str, str | None] {
    result: dict[str, str | None] = {"story": story_id, "epic": None, "milestone": None, "roadmap": None};
    if story_id not in story_epic { return result; }
    epic_id = story_epic[story_id];
    result["epic"] = epic_id;
    if epic_id not in epic_milestone { return result; }
    milestone_id = epic_milestone[epic_id];
    result["milestone"] = milestone_id;
    if milestone_id not in milestone_roadmap { return result; }
    result["roadmap"] = milestone_roadmap[milestone_id];
    return result;
}

def build_dependency_graph(edges: list[tuple[str, str]]) -> dict[str, list[str]] {
    graph: dict[str, list[str]] = {};
    for pair in edges {
        src = pair[0];
        dst = pair[1];
        if src not in graph { graph[src] = []; }
        graph[src].append(dst);
        if dst not in graph { graph[dst] = []; }
    }
    return graph;
}

def materialize_deps(graph: dict[str, list[str]]) -> tuple[dict[str, DepNode], list[str]] {
    nodes: dict[str, DepNode] = {};
    ids: list[str] = [];
    for nid in graph {
        if nid not in nodes {
            dn = DepNode(nid=nid);
            root ++> dn;
            nodes[nid] = dn;
        }
        ids.append(nid);
    }
    for src in graph {
        succs = graph[src] as list[str];
        for dst in succs {
            if dst not in nodes {
                dn2 = DepNode(nid=dst);
                root ++> dn2;
                nodes[dst] = dn2;
            }
            nodes[src] +>:Depends:+> nodes[dst];
        }
    }
    return (nodes, ids);
}

def detect_cycle(graph: dict[str, list[str]]) -> bool {
    (nodes, ids) = materialize_deps(graph);
    claimed: dict[str, bool] = {};
    cyclic = False;
    for nid in ids {
        if nid not in claimed {
            w = nodes[nid] spawn DepWalk(claimed=claimed, on_stack={}, order=[], cyclic=False);
            cyclic = cyclic or w.cyclic;
            claimed = w.claimed;
        }
    }
    return cyclic;
}

def topological_sort(graph: dict[str, list[str]]) -> list[str] {
    if detect_cycle(graph) { return []; }
    (nodes, ids) = materialize_deps(graph);
    claimed: dict[str, bool] = {};
    order: list[str] = [];
    for nid in ids {
        if nid not in claimed {
            w = nodes[nid] spawn DepWalk(claimed=claimed, on_stack={}, order=order, cyclic=False);
            claimed = w.claimed;
            order = w.order;
        }
    }
    rev: list[str] = [];
    i = len(order) - 1;
    while i >= 0 {
        rev.append(order[i]);
        i -= 1;
    }
    return rev;
}

with entry {
    st = Story(sid="s1", epic_ref="e1");
    root ++> st;
    ep = Epic(eid="e1", milestone_ref="m1");
    root ++> ep;
    ms = Milestone(mid="m1", roadmap_ref="r1");
    root ++> ms;
    rm = Roadmap(rid="r1");
    root ++> rm;
    st +>:StoryEpic:+> ep;
    ep +>:EpicMilestone:+> ms;
    ms +>:MilestoneRoadmap:+> rm;
    w = st spawn ChainWalker(claimed={}, result={});
    print(w.result);
}
