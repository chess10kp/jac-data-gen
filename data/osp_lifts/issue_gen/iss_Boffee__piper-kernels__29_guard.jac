"""OSP lift for Boffee/piper-kernels#29: ConvRot and staged memory-fusion work."""

node Hub {}
node Operator {
    has name: str;
    has stage: str = "standalone";
    has completed: bool = False;
    has requirements: list[str] = [];
}
edge Contains {}
edge DependsOn {}
edge Enables {}

obj Pipeline {
    has graph: Hub;
    has operators: dict[str, Operator] = {};
}

walker Catalog {
    has claimed: dict[str, bool] = {};
    has names: list[str] = [];

    can scan_hub with Hub entry {
        print("catalog");
        for op in [here ->:Contains:->][?:Operator] {
            visit :0: [op];
        }
    }

    can scan_operator with Operator entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.names.append(here.name);
        print(here.name);
    }
}

walker Closure {
    has claimed: dict[str, bool] = {};
    has names: list[str] = [];

    can walk_operator with Operator entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.names.append(here.name);
        print(here.name);
        for dep in [here ->:DependsOn:->][?:Operator] {
            visit :0: [dep];
        }
    }
}

walker Downstream {
    has claimed: dict[str, bool] = {};
    has names: list[str] = [];

    can walk_operator with Operator entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.name != self.start {
            self.names.append(here.name);
        }
        print(here.name);
        for child in [here ->:Enables:->][?:Operator] {
            visit :0: [child];
        }
    }

    has start: str = "";
}

def new_pipeline() -> Pipeline {
    graph_node: Hub = Hub();
    pipeline: Pipeline = Pipeline(graph=graph_node);
    return pipeline;
}

def register_operator(
    pipeline: Pipeline,
    name: str,
    requirements: list[str] | None = None,
    stage: str = "standalone"
) -> None {
    if name in pipeline.operators {
        return;
    }
    op: Operator = Operator(name=name, stage=stage);
    pipeline.operators[name] = op;
    pipeline.graph +>:Contains:+> op;

    names: list[str] = [];
    if requirements is not None {
        for requirement in requirements {
            names.append(requirement);
            op.requirements.append(requirement);
            if requirement in pipeline.operators {
                dep: Operator = pipeline.operators[requirement];
                op +>:DependsOn:+> dep;
                dep +>:Enables:+> op;
            }
        }
    }

    for prior_name in pipeline.operators {
        if prior_name != name {
            prior: Operator = pipeline.operators[prior_name];
            if name in prior.requirements {
                prior +>:DependsOn:+> op;
                op +>:Enables:+> prior;
            }
        }
    }
}

def complete_operator(pipeline: Pipeline, name: str) -> bool {
    if name not in pipeline.operators {
        return False;
    }
    op: Operator = pipeline.operators[name];
    op.completed = True;
    return True;
}

def available_operators(pipeline: Pipeline) -> list[str] {
    available: list[str] = [];
    w = pipeline.graph spawn Catalog(claimed={});
    for name in w.names {
        op: Operator = pipeline.operators[name];
        if op.completed == False {
            ready: bool = True;
            for dep in [op ->:DependsOn:->][?:Operator] {
                if dep.completed == False {
                    ready = False;
                }
            }
            if ready {
                available.append(name);
            }
        }
    }
    return sorted(available);
}

def dependency_closure(pipeline: Pipeline, name: str) -> list[str] {
    if name not in pipeline.operators {
        return [];
    }
    op: Operator = pipeline.operators[name];
    w = op spawn Closure(claimed={});
    return sorted(w.names);
}

def downstream_operators(pipeline: Pipeline, name: str) -> list[str] {
    if name not in pipeline.operators {
        return [];
    }
    op: Operator = pipeline.operators[name];
    w = op spawn Downstream(start=name, claimed={});
    return sorted(w.names);
}

test "completed operator unlocks independent work" {
    pipeline = new_pipeline();
    register_operator(pipeline, "source");
    register_operator(pipeline, "prepare", ["source"], "convrot");
    register_operator(pipeline, "fuse", ["prepare"], "diffusers");
    register_operator(pipeline, "independent", None, "portable");

    assert (available_operators(pipeline) == ["independent", "source"]);
    assert (complete_operator(pipeline, "source") == True);
    assert (available_operators(pipeline) == ["independent", "prepare"]);
    assert (complete_operator(pipeline, "prepare") == True);
    assert (available_operators(pipeline) == ["fuse", "independent"]);
}

test "diamond closure skips adversarial revisit" {
    pipeline = new_pipeline();
    register_operator(pipeline, "leaf");
    register_operator(pipeline, "left", ["leaf"]);
    register_operator(pipeline, "right", ["leaf"]);
    register_operator(pipeline, "target", ["right", "left"]);

    assert (dependency_closure(pipeline, "target") == ["leaf", "left", "right", "target"]);
    assert (downstream_operators(pipeline, "leaf") == ["left", "right", "target"]);
}

test "unknown operator ids are tolerated" {
    pipeline = new_pipeline();
    register_operator(pipeline, "known");

    assert (complete_operator(pipeline, "missing") == False);
    assert (dependency_closure(pipeline, "missing") == []);
    assert (downstream_operators(pipeline, "missing") == []);
}

test "cyclic requirements terminate without unlocking" {
    pipeline = new_pipeline();
    register_operator(pipeline, "a", ["b"]);
    register_operator(pipeline, "b", ["a"]);

    assert (available_operators(pipeline) == []);
    assert (dependency_closure(pipeline, "a") == ["a", "b"]);
}
