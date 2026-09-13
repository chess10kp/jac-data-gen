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
