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

test "add objects is idempotent" {
    leaf = Model(cid="leaf");
    collector = DeletionCollector();
    keys: list[str] = ["id-1"];

    added: dict[str, list[str]] = add_objects_to_collector(collector, leaf, keys);
    add_objects_to_collector(collector, leaf, keys);

    assert (added["leaf"] == ["id-1"]);
    assert (len(collector.objects["leaf"]) == 1);
}

test "diamond revisits a target once" {
    root_node = Model(cid="root");
    branch_b = Model(cid="b");
    branch_a = Model(cid="a");
    diamond = Model(cid="d");
    tail = Model(cid="x");

    root_node +>:Cascade:+> branch_b;
    root_node +>:Cascade:+> branch_a;
    branch_a +>:Cascade:+> diamond;
    branch_b +>:Cascade:+> diamond;
    diamond +>:Cascade:+> tail;

    collector = DeletionCollector();
    collector.objects["root"] = ["r"];
    result: dict[str, list[str]] = process_collector(root_node, collector);

    assert (sorted(result.keys()) == ["a", "b", "d", "root", "x"]);
    assert (len(result["d"]) == 1);
    assert (len(result["x"]) == 1);
}

test "unknown collector ids are preserved" {
    root_node = Model(cid="root");
    child = Model(cid="child");
    root_node +>:Cascade:+> child;

    collector = DeletionCollector();
    collector.objects["ghost"] = ["missing"];
    collector.objects["root"] = ["r"];
    result: dict[str, list[str]] = process_collector(root_node, collector);

    assert (sorted(result.keys()) == ["child", "ghost", "root"]);
    assert (result["ghost"] == ["missing"]);
    assert (result["child"] == ["r"]);
}

test "cycles terminate without duplicate collection" {
    root_node = Model(cid="root");
    child = Model(cid="child");
    root_node +>:Cascade:+> child;
    child +>:Cascade:+> root_node;

    collector = DeletionCollector();
    collector.objects["root"] = ["r"];
    result: dict[str, list[str]] = find_related_objects(collector, root_node);

    assert (sorted(result.keys()) == ["child", "root"]);
    assert (len(result["root"]) == 1);
    assert (len(result["child"]) == 1);
}
