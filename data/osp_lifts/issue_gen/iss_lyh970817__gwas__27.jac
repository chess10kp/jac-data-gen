node Component {
    has name: str;
}

node Catalog {}

edge Uses {}
edge Entry {}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can enter_catalog with Catalog entry {
        print("audit");
        for kid in [here ->:Entry:->][?:Component] {
            visit :0: [kid];
        }
    }

    can enter_component with Component entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.name);
        print(here.name);
        for kid in [here ->:Uses:->][?:Component] {
            visit :0: [kid];
        }
    }
}

def reachable_components(
    components: list[str],
    references: list[tuple[str, str]],
    production_roots: list[str]
) -> list[str] {
    nodes: dict[str, Component] = {};
    for name in components {
        component = Component(name=name);
        nodes[name] = component;
    }

    for pair in references {
        if pair[0] in nodes and pair[1] in nodes {
            source = nodes[pair[0]];
            target = nodes[pair[1]];
            source +>:Uses:+> target;
        }
    }

    catalog_node = Catalog();
    for name in production_roots {
        if name in nodes {
            start = nodes[name];
            catalog_node +>:Entry:+> start;
        }
    }

    w = catalog_node spawn ReachWalker(claimed={});
    return sorted(w.found);
}

def classify_components(
    components: list[str],
    references: list[tuple[str, str]],
    production_roots: list[str],
    retained: list[str],
    superseded: list[str]
) -> dict[str, str] {
    reachable = reachable_components(
        components,
        references,
        production_roots
    );
    result: dict[str, str] = {};

    for name in components {
        if name in reachable {
            result[name] = "active production dependency";
        } elif name in superseded {
            result[name] = "superseded duplicate";
        } elif name in retained {
            result[name] = "standalone reusable component intentionally retained";
        } else {
            result[name] = "orphaned";
        }
    }
    return result;
}

def dead_outputs(
    outputs: list[str],
    consumers: list[tuple[str, str]],
    published: list[str]
) -> list[str] {
    dead: list[str] = [];
    for output in outputs {
        used = False;
        for pair in consumers {
            if pair[0] == output {
                used = True;
            }
        }
        if not used and output not in published {
            dead.append(output);
        }
    }
    return sorted(dead);
}
