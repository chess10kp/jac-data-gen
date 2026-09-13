"""Idiomatic OSP lift for PingoLee/PormG.jl#459."""

node Model {
    has cid: str;
}

edge Cascade {}

obj DeletionCollector {
    has objects: dict[str, list[str]] = {};
}

walker CascadeCollector {
    has collector: DeletionCollector;
    has claimed: dict[str, bool] = {};

    can collect with Model entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print(here.cid);

        if here.cid in self.collector.objects {
            keys: list[str] = [];
            for key in self.collector.objects[here.cid] {
                keys.append(key);
            }
            for child in [here ->:Cascade:->][?:Model] {
                add_objects_to_collector(self.collector, child, keys);
                visit :0: [child];
            }
        }
    }
}

def add_objects_to_collector(
    collector: DeletionCollector,
    model: Model,
    keys: list[str]
) -> dict[str, list[str]] {
    if model.cid in collector.objects {
        for key in keys {
            if key not in collector.objects[model.cid] {
                collector.objects[model.cid].append(key);
            }
        }
    } else {
        copied: list[str] = [];
        for key in keys {
            copied.append(key);
        }
        collector.objects[model.cid] = copied;
    }
    return collector.objects;
}

def find_related_objects(
    collector: DeletionCollector,
    model: Model
) -> dict[str, list[str]] {
    w = model spawn CascadeCollector(collector=collector, claimed={});
    return collector.objects;
}

def process_collector(
    graph_root: Model,
    collector: DeletionCollector
) -> dict[str, list[str]] {
    return find_related_objects(collector, graph_root);
}
