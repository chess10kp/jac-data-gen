# PROGRAM iss_EpiAware__ComposableTuringIDModels_jl__298.jac
"""EpiAware/ComposableTuringIDModels.jl#298 observation-chain traversal API."""

node ObservationPart {
    has cid: str;
    has kind: str;
    has name: str;
    has delay: int = 0;
}

edge Contains {}

walker ChainWalker {
    has claimed: dict[str, bool] = {};
    has seen: list[ObservationPart] = [];

    can step with ObservationPart entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.seen.append(here);
        print(here.cid);
        for kid in [here ->:Contains:->][?:ObservationPart] {
            visit :0: [kid];
        }
    }
}

def _walk_parts(root_node: ObservationPart) -> list[ObservationPart] {
    w = root_node spawn ChainWalker(claimed={});
    return w.seen;
}

def traverse_observation(root_node: ObservationPart) -> list[str] {
    parts = _walk_parts(root_node);
    ids: list[str] = [];
    for part in parts {
        ids.append(part.cid);
    }
    return ids;
}

def find_by_type(
    root_node: ObservationPart,
    wanted_kind: str
) -> list[ObservationPart] {
    parts = _walk_parts(root_node);
    matches: list[ObservationPart] = [];
    for part in parts {
        if part.kind == wanted_kind {
            matches.append(part);
        }
    }
    return matches;
}

def find_by_id(
    root_node: ObservationPart,
    wanted_id: str
) -> list[ObservationPart] {
    parts = _walk_parts(root_node);
    matches: list[ObservationPart] = [];
    for part in parts {
        if part.cid == wanted_id {
            matches.append(part);
        }
    }
    return matches;
}

def update_by_type(
    root_node: ObservationPart,
    wanted_kind: str,
    replacement: ObservationPart
) -> ObservationPart {
    parts = find_by_type(root_node, wanted_kind);
    for part in parts {
        part.kind = replacement.kind;
        part.name = replacement.name;
        part.delay = replacement.delay;
    }
    return root_node;
}

def update_by_id(
    root_node: ObservationPart,
    wanted_id: str,
    replacement: ObservationPart
) -> ObservationPart {
    parts = find_by_id(root_node, wanted_id);
    for part in parts {
        part.kind = replacement.kind;
        part.name = replacement.name;
        part.delay = replacement.delay;
    }
    return root_node;
}

def lead_in(root_node: ObservationPart) -> int {
    parts = _walk_parts(root_node);
    total: int = 0;
    for part in parts {
        if part.kind == "LatentDelay" {
            total += part.delay - 1;
        }
    }
    return total;
}

def show_tree(root_node: ObservationPart) -> list[str] {
    parts = _walk_parts(root_node);
    lines: list[str] = [];
    for part in parts {
        lines.append(part.kind + ":" + part.name);
    }
    return lines;
}
