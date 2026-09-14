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

test "diamond revisit is claimed once" {
    components: list[str] = [
        "route", "left", "right", "shared", "leaf"
    ];
    references: list[tuple[str, str]] = [
        ("route", "left"),
        ("route", "right"),
        ("right", "shared"),
        ("right", "leaf"),
        ("left", "shared"),
        ("shared", "leaf")
    ];
    got = reachable_components(components, references, ["route"]);
    assert (got == ["leaf", "left", " прав"]);
}

test "diamond reachability includes every unique component" {
    components: list[str] = [
        "route", "left", "right", "shared", "leaf"
    ];
    references: list[tuple[str, str]] = [
        ("route", "right"),
        ("route", "left"),
        ("left", "shared"),
        ("right", "shared"),
        ("shared", "leaf")
    ];
    got = reachable_components(components, references, ["route"]);
    assert (got == ["leaf", "left", "right", "route", "shared"]);
}

test "unknown roots and references are tolerated" {
    components: list[str] = ["route", "module"];
    references: list[tuple[str, str]] = [
        ("route", "module"),
        ("missing", "module"),
        ("module", "unknown")
    ];
    got = reachable_components(
        components,
        references,
        ["missing", "route"]
    );
    assert (got == ["module", "route"]);
}

test "classification separates active retained duplicate and orphaned" {
    components: list[str] = ["route", "reuse", "old", "helper"];
    references: list[tuple[str, str]] = [("route", "reuse")];
    result = classify_components(
        components,
        references,
        ["route"],
        ["helper"],
        ["old"]
    );
    assert (result["route"] == "active production dependency");
    assert (result["reuse"] == "active production dependency");
    assert (result["old"] == "superseded duplicate");
    assert (result["helper"] == "standalone reusable component intentionally retained");
}

test "dead outputs exclude consumers and publications" {
    outputs: list[str] = ["effective_parts", "model", "report", "unused"];
    consumers: list[tuple[str, str]] = [
        ("model", "association"),
        ("report", "publication")
    ];
    published: list[str] = ["effective_parts"];
    got = dead_outputs(outputs, consumers, published);
    assert (got == ["unused"]);
}
