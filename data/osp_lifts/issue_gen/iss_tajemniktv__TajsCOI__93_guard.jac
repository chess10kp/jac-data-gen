node Transport {
    has cid: str;
    has category: str = "segment";
    has direction: str = "";
}

edge Link {}

obj Visualizer {
    has nodes: dict[str, Transport] = {};
    has highlighted: list[str] = [];
    has presentation: dict[str, str] = {};
    has direction_cues: dict[str, str] = {};
    has adapters: dict[str, bool] = {};
    has network_size: int = 0;
    has active: bool = false;
}

walker TraceNetwork {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has categories: dict[str, str] = {};
    has cues: dict[str, str] = {};

    can step with Transport entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        self.categories[here.cid] = here.category;
        if here.direction != "" {
            self.cues[here.cid] = here.direction;
        }
        print(here.cid);
        for kid in [here ->:Link:->][?:Transport] {
            visit :0: [kid];
        }
    }
}

def new_visualizer() -> Visualizer {
    return Visualizer();
}

def add_transport(
    state: Visualizer,
    cid: str,
    category: str = "segment",
    direction: str = ""
) -> Transport {
    nd = Transport(cid=cid, category=category, direction=direction);
    state.nodes[cid] = nd;
    return nd;
}

def connect_transport(
    state: Visualizer,
    left_id: str,
    right_id: str
) -> bool {
    if left_id not in state.nodes {
        return False;
    }
    if right_id not in state.nodes {
        return False;
    }
    left_node = state.nodes[left_id];
    right_node = state.nodes[right_id];
    left_node +>:Link:+> right_node;
    right_node +>:Link:+> left_node;
    return True;
}

def register_adapter(state: Visualizer, category: str) -> bool {
    if category == "" {
        return False;
    }
    state.adapters[category] = True;
    return True;
}

def presentation_for(state: Visualizer, category: str) -> str {
    if category == "connector" {
        return "connector";
    }
    if category == "endpoint" {
        return "endpoint";
    }
    if category in state.adapters {
        return category;
    }
    return "ordinary";
}

def trace_network(state: Visualizer, selected_id: str) -> list[str] {
    clear_selection(state);
    if selected_id not in state.nodes {
        return [];
    }
    root_node = state.nodes[selected_id];
    w = root_node spawn TraceNetwork(claimed={});
    for cid in w.found {
        state.highlighted.append(cid);
        state.presentation[cid] = presentation_for(state, w.categories[cid]);
        if cid in w.cues {
            state.direction_cues[cid] = w.cues[cid];
        }
    }
    state.network_size = len(w.found);
    state.active = True;
    print(state.network_size);
    return sorted(state.highlighted);
}

def clear_selection(state: Visualizer) -> list[str] {
    old: list[str] = [];
    for cid in state.highlighted {
        old.append(cid);
    }
    state.highlighted = [];
    state.presentation = {};
    state.direction_cues = {};
    state.network_size = 0;
    state.active = False;
    return sorted(old);
}

def deactivate_visualizer(state: Visualizer) -> list[str] {
    return clear_selection(state);
}

test "adversarial diamond revisit" {
    v = new_visualizer();
    add_transport(v, "source", "segment");
    add_transport(v, "left", "connector");
    add_transport(v, "right", "connector");
    add_transport(v, "join", "endpoint");
    assert (connect_transport(v, "source", "left"));
    assert (connect_transport(v, "source", "right"));
    assert (connect_transport(v, "right", "join"));
    assert (connect_transport(v, "left", "join"));
    found = trace_network(v, "source");
    assert (found == ["join", "left", "right", "source"]);
    assert (v.network_size == 4);
}

test "unknown selection and connection are tolerated" {
    v = new_visualizer();
    add_transport(v, "only", "segment");
    assert (connect_transport(v, "missing", "only") == False);
    assert (trace_network(v, "missing") == []);
    assert (v.network_size == 0);
    assert (v.active == False);
}

test "clear removes every overlay" {
    v = new_visualizer();
    add_transport(v, "sink", "endpoint", "in");
    assert (trace_network(v, "sink") == ["sink"]);
    removed = clear_selection(v);
    assert (removed == ["sink"]);
    assert (len(v.highlighted) == 0);
    assert (len(v.presentation) == 0);
    assert (len(v.direction_cues) == 0);
    assert (v.active == False);
}

test "selection stays within connected component" {
    v = new_visualizer();
    add_transport(v, "belt", "segment");
    add_transport(v, "mod", "third_party");
    add_transport(v, "machine", "endpoint");
    add_transport(v, "island", "segment");
    assert (register_adapter(v, "third_party"));
    assert (connect_transport(v, "belt", "mod"));
    assert (connect_transport(v, "mod", "machine"));
    found = trace_network(v, "belt");
    assert (found == ["belt", "machine", "mod"]);
    assert (v.presentation["belt"] == "ordinary");
    assert (v.presentation["mod"] == "third_party");
    assert (v.presentation["machine"] == "endpoint");
    assert ("island" not in found);
}

test "deactivation is idempotent" {
    v = new_visualizer();
    add_transport(v, "segment", "segment");
    assert (trace_network(v, "segment") == ["segment"]);
    assert (deactivate_visualizer(v) == ["segment"]);
    assert (deactivate_visualizer(v) == []);
}
