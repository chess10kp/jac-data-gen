"""HarrisRamosBaroni/skills#1"""

node Artifact {
    has cid: str;
    has kind: str;
}

edge Reference {}

obj CodeMap {
    has entries: dict[str, Artifact] = {};
}

walker Closure {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has parents: dict[str, str] = {};

    can step with Artifact entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print(here.cid);

        if here.cid not in self.parents {
            self.parents[here.cid] = here.cid;
        }

        for kid in [here ->:Reference:->][?:Artifact] {
            if kid.cid not in self.parents {
                self.parents[kid.cid] = here.cid;
            }
            visit :0: [kid];
        }
    }
}

def make_map() -> CodeMap {
    return CodeMap();
}

def add_artifact(graph: CodeMap, cid: str, kind: str) -> None {
    if cid in graph.entries {
        return;
    }
    item = Artifact(cid=cid, kind=kind);
    graph.entries[cid] = item;
}

def link_artifacts(
    graph: CodeMap,
    source_id: str,
    target_id: str
) -> bool {
    if source_id not in graph.entries || target_id not in graph.entries {
        return False;
    }
    source: Artifact = graph.entries[source_id];
    target: Artifact = graph.entries[target_id];
    source +>:Reference:+> target;
    return True;
}

def artifact_kind(graph: CodeMap, cid: str) -> str {
    if cid not in graph.entries {
        return "";
    }
    return graph.entries[cid].kind;
}

def reachable_ids(graph: CodeMap, start_id: str) -> list[str] {
    if start_id not in graph.entries {
        return [];
    }
    start: Artifact = graph.entries[start_id];
    w = start spawn Closure(claimed={});
    return sorted(w.found);
}

def blast_radius(graph: CodeMap, start_id: str) -> int {
    ids: list[str] = reachable_ids(graph, start_id);
    if len(ids) == 0 {
        return 0;
    }
    return len(ids) - 1;
}

def navigation_path(
    graph: CodeMap,
    start_id: str,
    target_id: str
) -> list[str] {
    if start_id not in graph.entries || target_id not in graph.entries {
        return [];
    }

    start: Artifact = graph.entries[start_id];
    w = start spawn Closure(claimed={});
    if target_id not in w.claimed {
        return [];
    }

    reverse_path: list[str] = [];
    current: str = target_id;
    while True {
        reverse_path.append(current);
        if current == start_id {
            break;
        }
        if current not in w.parents {
            return [];
        }
        current = w.parents[current];
    }

    result: list[str] = [];
    i = len(reverse_path) - 1;
    while i >= 0 {
        result.append(reverse_path[i]);
        i -= 1;
    }
    return result;
}

test "diamond_revisit_is_claimed_once" {
    graph = make_map();
    add_artifact(graph, "root", "module");
    add_artifact(graph, "left", "source");
    add_artifact(graph, "right", "source");
    add_artifact(graph, "shared", "reference");
    link_artifacts(graph, "root", "right");
    link_artifacts(graph, "root", "left");
    link_artifacts(graph, "right", "shared");
    link_artifacts(graph, "left", "shared");

    assert (sorted(reachable_ids(graph, "root")) == ["left", "right", "root", "shared"]);
    assert (blast_radius(graph, "root") == 3);
    path = navigation_path(graph, "root", "shared");
    assert (len(path) == 3);
    assert (path[0] == "root");
    assert (path[2] == "shared");
}

test "unknown_ids_are_tolerated" {
    graph = make_map();
    add_artifact(graph, "known", "file");

    assert (reachable_ids(graph, "missing") == []);
    assert (navigation_path(graph, "known", "missing") == []);
    assert (navigation_path(graph, "missing", "known") == []);
    assert (link_artifacts(graph, "known", "missing") == False);
    assert (artifact_kind(graph, "missing") == "");
}

test "self_cycle_has_one_visit" {
    graph = make_map();
    add_artifact(graph, "solo", "file");
    link_artifacts(graph, "solo", "solo");

    assert (reachable_ids(graph, "solo") == ["solo"]);
    assert (blast_radius(graph, "solo") == 0);
    assert (navigation_path(graph, "solo", "solo") == ["solo"]);
}

test "duplicate_artifacts_do_not_replace_state" {
    graph = make_map();
    add_artifact(graph, "T1", "ticket");
    add_artifact(graph, "T1", "spec");

    assert (artifact_kind(graph, "T1") == "ticket");
    assert (reachable_ids(graph, "T1") == ["T1"]);
}
