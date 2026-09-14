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

test "linear observation chain" {
    graph_root = ObservationPart(
        cid="root", kind="Split", name="root"
    );
    delay_a = ObservationPart(
        cid="delay-a", kind="LatentDelay", name="infection", delay=3
    );
    delay_b = ObservationPart(
        cid="delay-b", kind="LatentDelay", name="shedding", delay=5
    );
    error = ObservationPart(
        cid="error", kind="ErrorModel", name="negative-binomial"
    );
    graph_root +>:Contains:+> delay_a;
    delay_a +>:Contains:+> delay_b;
    delay_b +>:Contains:+> error;
    assert (lead_in(graph_root) == 6);
    assert (show_tree(graph_root) == [
        "Split:root",
        "LatentDelay:infection",
        "LatentDelay:shedding",
        "ErrorModel:negative-binomial"
    ]);
}

test "diamond revisits are skipped without truncating traversal" {
    graph_root = ObservationPart(
        cid="root", kind="Split", name="root"
    );
    right = ObservationPart(
        cid="right", kind="Wrapper", name="right"
    );
    left = ObservationPart(
        cid="left", kind="Wrapper", name="left"
    );
    shared = ObservationPart(
        cid="shared", kind="LatentDelay", name="shared", delay=2
    );
    deep = ObservationPart(
        cid="deep", kind="ErrorModel", name="deep"
    );
    graph_root +>:Contains:+> right;
    graph_root +>:Contains:+> left;
    left +>:Contains:+> shared;
    right +>:Contains:+> deep;
    right +>:Contains:+> shared;
    seen = traverse_observation(graph_root);
    assert (len(seen) == 5);
    assert (sorted(seen) == ["deep", "left", "right", "root", "shared"]);
}

test "find and update by component type" {
    graph_root = ObservationPart(
        cid="root", kind="Split", name="root"
    );
    first = ObservationPart(
        cid="first", kind="LatentDelay", name="first", delay=3
    );
    second = ObservationPart(
        cid="second", kind="LatentDelay", name="second", delay=5
    );
    graph_root +>:Contains:+> first;
    first +>:Contains:+> second;
    replacement = ObservationPart(
        cid="replacement", kind="LatentDelay", name="updated", delay=2
    );
    found = find_by_type(graph_root, "LatentDelay");
    assert (len(found) == 2);
    update_by_type(graph_root, "LatentDelay", replacement);
    assert (lead_in(graph_root) == 2);
    assert (show_tree(graph_root) == [
        "Split:root", "LatentDelay:updated", "LatentDelay:updated"
    ]);
}

test "unknown identifiers are tolerated" {
    graph_root = ObservationPart(
        cid="root", kind="ErrorModel", name="base"
    );
    replacement = ObservationPart(
        cid="new", kind="LatentDelay", name="unused", delay=4
    );
    assert (len(find_by_id(graph_root, "missing")) == 0);
    update_by_id(graph_root, "missing", replacement);
    assert (show_tree(graph_root) == ["ErrorModel:base"]);
}

test "single node and empty branch are valid" {
    graph_root = ObservationPart(
        cid="empty", kind="Split", name="empty"
    );
    assert (traverse_observation(graph_root) == ["empty"]);
    assert (lead_in(graph_root) == 0);
    assert (show_tree(graph_root) == ["Split:empty"]);
}
