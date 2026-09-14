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
