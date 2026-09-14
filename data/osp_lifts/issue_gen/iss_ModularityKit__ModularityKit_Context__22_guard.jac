# ModularityKit/ModularityKit.Context#22

node ContextTask {
    has name: str;
    has action: str;
    has level: int = 0;
}

node ContextGraph {
    has tasks: list[ContextTask] = [];
    has cyclic: bool = False;
}

edge Contains {}
edge DependsOn {}

obj ContextSpec {
    has name: str;
    has action: str;
    has depends_on: list[str] = [];
}

obj ContextGraphBuilder {
    has specs: list[ContextSpec] = [];

    can AddNode(
        name: str,
        action: str,
        dependsOn: list[str] | None = None
    ) -> ContextGraphBuilder {
        deps: list[str] = [];
        if dependsOn is not None {
            for dep_id in dependsOn {
                deps.append(dep_id);
            }
        }
        self.specs.append(
            ContextSpec(name=name, action=action, depends_on=deps)
        );
        return self;
    }

    can Build() -> ContextGraph {
        graph_node = ContextGraph();
        by_name: dict[str, ContextTask] = {};

        for spec in self.specs {
            task_node = ContextTask(name=spec.name, action=spec.action);
            by_name[spec.name] = task_node;
            graph_node.tasks.append(task_node);
            graph_node +>:Contains:+> task_node;
        }

        for spec in self.specs {
            task_node = by_name[spec.name];
            for dep_id in spec.depends_on {
                if dep_id in by_name {
                    predecessor = by_name[dep_id];
                    predecessor +>:DependsOn:+> task_node;
                }
            }
        }

        w = graph_node spawn CycleWalker(claimed={}, active={}, cyclic=False);
        graph_node.cyclic = w.cyclic;
        return graph_node;
    }
}

obj ContextRun {
    has context_id: str;
    has order: list[str] = [];
    has events: list[str] = [];
}

walker CycleWalker {
    has claimed: dict[str, bool] = {};
    has active: dict[str, bool] = {};
    has cyclic: bool = False;

    can scan_graph with ContextGraph entry {
        print("cycle scan");
        for kid in [here ->:Contains:->][?:ContextTask] {
            visit :0: [kid];
        }
    }

    can scan_task with ContextTask entry {
        if here.cid in self.active {
            self.cyclic = True;
            skip;
        }
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.active[here.cid] = True;
        for predecessor in [here <-:DependsOn:<-][?:ContextTask] {
            visit :0: [predecessor];
        }
        self.active[here.cid] = False;
    }
}

walker ExecuteWalker {
    has run: ContextRun;
    has claimed: dict[str, bool] = {};

    can execute_graph with ContextGraph entry {
        print("execute graph");
        for kid in [here ->:Contains:->][?:ContextTask] {
            visit :0: [kid];
        }
    }

    can execute_task with ContextTask entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;

        here.level = 0;
        for predecessor in [here <-:DependsOn:<-][?:ContextTask] {
            visit :0: [predecessor];
            if predecessor.level + 1 > here.level {
                here.level = predecessor.level + 1;
            }
        }

        self.run.events.append(
            self.run.context_id + ":start:" + here.name
        );
        print(
            self.run.context_id + ":run:" + here.name
        );
        self.run.events.append(
            self.run.context_id + ":complete:" + here.name
        );
        self.run.order.append(here.name);
    }
}

obj ContextManager {
    can ExecuteGraphAsync(
        context_id: str,
        graph: ContextGraph
    ) -> list[str] {
        run = ContextRun(context_id=context_id);
        if graph.cyclic {
            print("cycle rejected");
            return run.order;
        }
        w = graph spawn ExecuteWalker(run=run, claimed={});
        return run.order;
    }
}

test "diamond schedules dependencies and parallel branches" {
    builder = ContextGraphBuilder();
    builder.AddNode("fetch_order", "fetch_order");
    builder.AddNode("fetch_customer", "fetch_customer");
    builder.AddNode(
        "validate",
        "validate",
        dependsOn=["fetch_order", "fetch_customer"]
    );
    builder.AddNode("save", "save", dependsOn=["validate"]);

    graph_node = builder.Build();
    manager = ContextManager();
    got = manager.ExecuteGraphAsync("ctx-1", graph_node);

    assert (sorted(got) == sorted([
        "fetch_order",
        "fetch_customer",
        "validate",
        "save"
    ]));
    assert (graph_node.tasks[0].level == graph_node.tasks[1].level);
    assert (graph_node.tasks[2].level > graph_node.tasks[0].level);
    assert (graph_node.tasks[3].level > graph_node.tasks[2].level);
}

test "unknown dependency is tolerated" {
    builder = ContextGraphBuilder();
    builder.AddNode(
        "validate",
        "validate",
        dependsOn=["missing-task"]
    );

    graph_node = builder.Build();
    manager = ContextManager();
    got = manager.ExecuteGraphAsync("ctx-2", graph_node);

    assert (not graph_node.cyclic);
    assert (got == ["validate"]);
}

test "cycle is rejected" {
    builder = ContextGraphBuilder();
    builder.AddNode("a", "a", dependsOn=["b"]);
    builder.AddNode("b", "b", dependsOn=["a"]);

    graph_node = builder.Build();
    manager = ContextManager();
    got = manager.ExecuteGraphAsync("ctx-3", graph_node);

    assert (graph_node.cyclic);
    assert (len(got) == 0);
}

test "empty graph executes cleanly" {
    builder = ContextGraphBuilder();
    graph_node = builder.Build();
    manager = ContextManager();
    got = manager.ExecuteGraphAsync("ctx-empty", graph_node);

    assert (not graph_node.cyclic);
    assert (len(got) == 0);
}
