"""Competency Criteria Group removal with progress protection.

openedx/openedx-core#675 lifted to OSP: groups and criteria become
distinct archetypes under one typed Contains edge family; learner status
rows become ProgressOn cross-link edges. The depth cap is an ascent walk
counting ancestors; removal is two-phase -- a SubtreeFlood with a
once-only claim map collects the closure, the facade probes any incoming
ProgressOn link and then either flips archived flags or disconnects and
unregisters. Insertion order of Contains edges is preserved so the
per-group evaluation order stays observable.
"""
node GroupNode {
    has name: str;
    has archived: bool = False;
}
node CriterionNode {
    has name: str;
    has archived: bool = False;
}
node PersonNode { has learner_id: str; }
edge Contains {}
edge ProgressOn {}

"""Tree handle: id resolution through this lookup map is domain API."""
obj Mastery {
    has nodes: dict[str, GroupNode | CriterionNode];

    def resolve(name: str) -> Any {
        return self.nodes.get(name);
    }
}

def build_mastery(root_name: str) -> Mastery {
    m = Mastery(nodes={});
    g = GroupNode(name=root_name);
    root ++> g;
    m.nodes[root_name] = g;
    return m;
}

walker DepthAscent {
    has visited: dict[str, bool];
    has depth: int = 0;

    can step with GroupNode entry {
        if here.name in self.visited {
            skip;  # corrupt cycles stop climbing
        }
        self.visited[here.name] = True;
        parents: list[GroupNode] = [here <-:Contains:<-];
        if len(parents) == 0 {
            disengage;
        }
        self.depth += 1;
        visit [parents[0]];
    }
}

def add_group(m: Mastery, name: str, parent: str | None = None) {
    # source contract: unknown parent -> KeyError; criterion parent ->
    # ValueError("criteria are leaves"); duplicate names silently overwrite
    if parent is not None {
        p = m.resolve(parent);
        if p is None {
            raise KeyError("unknown parent");
        }
        if not isinstance(p, GroupNode) {
            raise ValueError("criteria are leaves");
        }
        w = p spawn DepthAscent(visited={});
        if w.depth + 1 >= 3 {
            raise ValueError("nesting exceeds depth 3");
        }
    } else {
        p = None;
    }
    g = m.resolve(name);
    if g is None or not isinstance(g, GroupNode) {
        # fresh registration (a stale criterion id gets replaced wholesale)
        old = m.nodes.pop(name, None);
        if old is not None {
            del old;
        }
        g = GroupNode(name=name);
        root ++> g;
        m.nodes[name] = g;
    }
    if parent is not None {
        # re-point under the (possibly new) parent
        for op in [g <-:Contains:<-] {
            op del ->:Contains:-> g;
        }
        p2 = m.resolve(parent);
        if p2 is not None {
            p2 +>:Contains:+> g;
        }
    }
}

def add_criterion(m: Mastery, name: str, parent_group: str) -> CriterionNode | None {
    p = m.resolve(parent_group);
    if p is None or not isinstance(p, GroupNode) {
        raise KeyError("unknown parent group");
    }
    c = CriterionNode(name=name);
    root ++> c;
    m.nodes[name] = c;
    p +>:Contains:+> c;
    return c;
}

def record_progress(m: Mastery, learner: str, criterion: str) -> CriterionNode | None {
    target = m.resolve(criterion);
    if target is None or not isinstance(target, CriterionNode) {
        raise KeyError("unknown criterion");
    }
    person = PersonNode(learner_id=learner);
    root ++> person;
    person +>:ProgressOn:+> target;
    return target;
}

"""Cross-link reachability: sorted learners touching any leaf below."""
def progress_in_subtree(m: Mastery, root_name: str) -> list[str] | None {
    start = m.resolve(root_name);
    if start is None {
        raise KeyError("unknown group");
    }
    w = start spawn SubtreeFlood(claimed={});
    people: list[str] = [];
    for n in w.found {
        if isinstance(n, CriterionNode) {
            learners: list[PersonNode] = [n <-:ProgressOn:<-];
            for p in learners {
                if p.learner_id not in people {
                    people.append(p.learner_id);
                }
            }
        }
    }
    return sorted(people);
}

"""Insertion order within this group only -- the evaluation order."""
def list_criteria_ordered(m: Mastery, group: str) -> list[str] | None {
    g = m.resolve(group);
    if g is None or not isinstance(g, GroupNode) {
        raise KeyError("unknown group");
    }
    out: list[str] = [];
    kids: list[GroupNode | CriterionNode] = [g ->:Contains:->];
    for k in kids {
        if isinstance(k, CriterionNode) and not k.archived {
            out.append(k.name);
        }
    }
    return out;
}

"""Two-phase removal: archive-only once any progress exists below."""
def remove_group(m: Mastery, root_name: str) -> dict {
    start = m.resolve(root_name);
    if start is None or not isinstance(start, GroupNode) {
        raise KeyError("unknown group");
    }
    # Phase 1: collect closure + probe progress links.
    w = start spawn SubtreeFlood(claimed={});
    doomed_names: list[str] = [start.name];
    for n in w.found {
        if n.name != start.name {
            doomed_names.append(n.name);
        }
    }
    affected = progress_in_subtree(m, root_name);
    result: dict = {"fate": "deleted", "removed": []};
    if affected is not None and len(affected) > 0 {
        result["fate"] = "archived";
        # apply outside collection: flip flags only, data preserved
        for n in w.found {
            n.archived = True;
        }
    } else {
        parents: list[GroupNode] = [start <-:Contains:<-];
        if len(parents) > 0 {
            par = parents[0];
            par del ->:Contains:-> start;
        }
        for name in doomed_names {  # unregister outside the walk
            m.nodes.pop(name, None);
        }
    }
    ordered = sorted(doomed_names);
    result["removed"] = ordered;
    return result;
}

def live_nodes(m: Mastery) -> list[str] {
    out: list[str] = [];
    keys: list[str] = [];
    for k in m.nodes.keys() {
        keys.append(k);
    }
    for k in sorted(keys) {
        nd = m.resolve(k);
        if isinstance(nd, GroupNode) {
            if not nd.archived {
                out.append(k);
            }
        } elif isinstance(nd, CriterionNode) {
            if not nd.archived {
                out.append(k);
            }
        }
    }
    return out;
}

"""Floods Contains edges; once-only claim map is the cycle policy."""
walker SubtreeFlood {
    has claimed: dict[str, bool];
    has found: list[GroupNode | CriterionNode] = [];

    can step with GroupNode entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.found.append(here);
        visit [->:Contains:->];
    }

    can step_leaf with CriterionNode entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.found.append(here);
    }
}
