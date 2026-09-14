# iss_Heliobond__backend__454.jac

node FlagSet {}
node Flag {
    has name: str;
    has enabled: bool = False;
    has rollout_percentage: int = 100;
}
edge Contains {}
edge DependsOn {}

obj FlagSpec {
    has name: str;
    has enabled: bool = False;
    has rollout_percentage: int = 100;
    has depends_on: list[str] = [];
}

obj EvaluationResult {
    has value: bool = False;
    has dependency_cycle: bool = False;
}

walker FlagEvaluation {
    has target: str;
    has ctx: dict[str, str] = {};
    has claimed: dict[str, bool] = {};
    has found: bool = False;
    has value: bool = True;
    has dependency_cycle: bool = False;

    can begin with FlagSet entry {
        print("evaluating " + self.target);
        for flag in [here ->:Contains:->][?:Flag] {
            if flag.name == self.target {
                self.found = True;
                visit :0: [flag];
            }
        }
    }

    can inspect with Flag entry {
        if here.name in self.claimed {
            self.dependency_cycle = True;
            skip;
        }
        self.claimed[here.name] = True;

        if here.enabled == False {
            self.value = False;
        }
        if here.rollout_percentage < 100 {
            self.value = False;
        }

        for dependency in [here ->:DependsOn:->][?:Flag] {
            visit :0: [dependency];
        }
    }
}

def loadFlags(specs: list[FlagSpec]) -> FlagSet {
    graph: FlagSet = FlagSet();

    for spec in specs {
        flag_node: Flag = Flag(
            name=spec.name,
            enabled=spec.enabled,
            rollout_percentage=spec.rollout_percentage
        );
        graph +>:Contains:+> flag_node;
    }

    for spec in specs {
        for source in [graph ->:Contains:->][?:Flag] {
            if source.name == spec.name {
                for dependency_name in spec.depends_on {
                    for target in [graph ->:Contains:->][?:Flag] {
                        if target.name == dependency_name {
                            source +>:DependsOn:+> target;
                        }
                    }
                }
            }
        }
    }
    return graph;
}

def evaluateFlag(
    graph: FlagSet,
    flag_name: str,
    ctx: dict[str, str]
) -> EvaluationResult {
    evaluation: FlagEvaluation = graph spawn FlagEvaluation(
        target=flag_name,
        ctx=ctx,
        claimed={}
    );
    return EvaluationResult(
        value=evaluation.found
            && evaluation.value
            && (evaluation.dependency_cycle == False),
        dependency_cycle=evaluation.dependency_cycle
    );
}

test "circular dependency returns dependency cycle" {
    graph = loadFlags([
        FlagSpec(name="a", enabled=True, depends_on=["b"]),
        FlagSpec(name="b", enabled=True, depends_on=["a"])
    ]);
    result = evaluateFlag(graph, "a", {});
    assert (result.value == False);
    assert (result.dependency_cycle == True);
}

test "diamond revisit is claimed and skipped" {
    graph = loadFlags([
        FlagSpec(name="a", enabled=True, depends_on=["b", "c"]),
        FlagSpec(name="b", enabled=True, depends_on=["d"]),
        FlagSpec(name="c", enabled=True, depends_on=["d"]),
        FlagSpec(name="d", enabled=True)
    ]);
    result = evaluateFlag(graph, "a", {});
    assert (result.value == False);
    assert (result.dependency_cycle == True);
}

test "unknown dependency is tolerated" {
    graph = loadFlags([
        FlagSpec(name="a", enabled=True, depends_on=["missing"])
    ]);
    result = evaluateFlag(graph, "a", {});
    assert (result.value == True);
    assert (result.dependency_cycle == False);
}

test "unknown flag and disabled flags are false" {
    graph = loadFlags([
        FlagSpec(name="off", enabled=False),
        FlagSpec(name="empty", enabled=True, rollout_percentage=0)
    ]);
    unknown_result = evaluateFlag(graph, "missing", {});
    off_result = evaluateFlag(graph, "off", {});
    empty_result = evaluateFlag(graph, "empty", {});
    assert (unknown_result.value == False);
    assert (off_result.value == False);
    assert (empty_result.value == False);
}
