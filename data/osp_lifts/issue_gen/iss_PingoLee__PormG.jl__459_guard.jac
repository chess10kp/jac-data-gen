# iss_PingoLee__PormG.jl__459.jac
# PingoLee/PormG.jl#459: collect cascade work before mutating collector.objects.

node Model {
    has cid: str;
}

edge Cascade {}

obj DeletionCollector {
    has objects: dict[str, list[str]] = {};
    has models: dict[str, Model] = {};
}

walker CascadeCollector {
    has collector: DeletionCollector;
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Model entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        if here.cid not in self.collector.objects {
            self.collector.objects[here.cid] = [];
        }
        print(here.cid);
        for child in [here ->:Cascade:->][?:Model] {
            visit :0: [child];
        }
    }
}

def new_model(cid: str) -> Model {
    return Model(cid=cid);
}

def make_collector() -> DeletionCollector {
    return DeletionCollector();
}

def link_cascade(parent: Model, child: Model) -> None {
    parent +>:Cascade:+> child;
    return None;
}

def add_objects_to_collector(
    collector: DeletionCollector,
    model: Model,
    keys: list[str]
) -> None {
    collector.models[model.cid] = model;
    if model.cid not in collector.objects {
        collector.objects[model.cid] = [];
    }
    for key in keys {
        if key not in collector.objects[model.cid] {
            collector.objects[model.cid].append(key);
        }
    }
    return None;
}

def find_related_objects(
    collector: DeletionCollector,
    model: Model,
    keys: list[str]
) -> list[str] {
    add_objects_to_collector(collector, model, keys);
    w = model spawn CascadeCollector(collector=collector);
    return w.found;
}

def collected_model_ids(collector: DeletionCollector) -> list[str] {
    ids: list[str] = [];
    for model_id in collector.objects {
        ids.append(model_id);
    }
    return ids;
}

def process_collector(collector: DeletionCollector) -> list[str] {
    seed_ids: list[str] = [];
    for model_id in collector.objects {
        seed_ids.append(model_id);
    }
    for model_id in seed_ids {
        if model_id in collector.models {
            model = collector.models[model_id];
            find_related_objects(collector, model, collector.objects[model_id]);
        }
    }
    return collected_model_ids(collector);
}

test "diamond revisit is claimed once" {
    collector = make_collector();
    root_node = new_model("root");
    left = new_model("left");
    right = new_model("right");
    shared = new_model("shared");
    link_cascade(root_node, left);
    link_cascade(root_node, right);
    link_cascade(left, shared);
    link_cascade(right, shared);
    keys: list[str] = ["root-key"];
    add_objects_to_collector(collector, root_node, keys);
    ids = process_collector(collector);
    assert (sorted(ids) == ["left", "right", "root", "shared"]);
    assert (len(collector.objects["shared"]) == 0);
}

test "unknown model id is tolerated" {
    collector = make_collector();
    ghost = new_model("ghost");
    add_objects_to_collector(collector, ghost, ["ghost-key"]);
    collector.objects["missing"] = [];
    ids = process_collector(collector);
    assert (sorted(ids) == ["ghost", "missing"]);
}

test "duplicate keys remain single entries" {
    collector = make_collector();
    leaf = new_model("leaf");
    add_objects_to_collector(collector, leaf, ["k", "k", "m"]);
    ids = process_collector(collector);
    assert (sorted(ids) == ["leaf"]);
    assert (len(collector.objects["leaf"]) == 2);
}

test "cyclic cascade terminates" {
    collector = make_collector();
    first = new_model("first");
    second = new_model("second");
    link_cascade(first, second);
    link_cascade(second, first);
    add_objects_to_collector(collector, first, ["first-key"]);
    ids = process_collector(collector);
    assert (sorted(ids) == ["first", "second"]);
}

test "isolated model is collected" {
    collector = make_collector();
    only = new_model("only");
    add_objects_to_collector(collector, only, []);
    ids = process_collector(collector);
    assert (sorted(ids) == ["only"]);
}
