# PROGRAM iss_leonarduk__issue-worm__103.jac
"""Dependency graph validation for leonarduk/issue-worm#103."""

node Package {
    has name: str;
    has version: str;
}

edge Requires {}

obj DependencyGraph {
    has packages: dict[str, Package] = {};
    has conflicts: list[str] = [];
    has missing: list[str] = [];
}

walker Closure {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Package entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.found.append(here.name);
        print("checked " + here.name);
        for dependency in [here ->:Requires:->][?:Package] {
            visit :0: [dependency];
        }
    }
}

def register_package(
    graph: DependencyGraph,
    name: str,
    version: str
) -> bool {
    if name in graph.packages {
        existing: Package = graph.packages[name];
        if existing.version == version {
            return True;
        }
        conflict: str = "version:" + name;
        if conflict not in graph.conflicts {
            graph.conflicts.append(conflict);
        }
        return False;
    }
    package: Package = Package(name=name, version=version);
    graph.packages[name] = package;
    return True;
}

def add_dependency(
    graph: DependencyGraph,
    source: str,
    target: str
) -> bool {
    if source not in graph.packages {
        marker: str = "missing:" + source + "->" + target;
        if marker not in graph.missing {
            graph.missing.append(marker);
        }
        return False;
    }
    if target not in graph.packages {
        marker: str = "missing:" + source + "->" + target;
        if marker not in graph.missing {
            graph.missing.append(marker);
        }
        return False;
    }
    source_package: Package = graph.packages[source];
    target_package: Package = graph.packages[target];
    source_package +>:Requires:+> target_package;
    return True;
}

def resolve_closure(
    graph: DependencyGraph,
    package_name: str
) -> list[str] {
    if package_name not in graph.packages {
        return [];
    }
    start: Package = graph.packages[package_name];
    w = start spawn Closure(claimed={});
    return sorted(w.found);
}

def validate_resolution(
    graph: DependencyGraph,
    requested: list[str]
) -> list[str] {
    issues: list[str] = [];
    for package_name in requested {
        if package_name not in graph.packages {
            issues.append("unknown:" + package_name);
        }
    }
    for conflict in graph.conflicts {
        issues.append(conflict);
    }
    for missing in graph.missing {
        issues.append(missing);
    }
    return sorted(issues);
}

# TESTS
test "full dependency graph resolves together" {
    graph = DependencyGraph();
    assert (register_package(graph, "issue-worm", "1.0.0") == True);
    assert (register_package(graph, "issue-worm-pro", "1.0.0") == True);
    assert (register_package(graph, "cicaid-devtools", "0.4.0") == True);
    assert (add_dependency(graph, "issue-worm", "issue-worm-pro") == True);
    assert (add_dependency(graph, "issue-worm-pro", "cicaid-devtools") == True);
    assert (resolve_closure(graph, "issue-worm") == ["cicaid-devtools", "issue-worm", "issue-worm-pro"]);
    assert (validate_resolution(graph, ["issue-worm", "issue-worm-pro", "cicaid-devtools"]) == []);
}

test "diamond revisit and cycle are skipped" {
    graph = DependencyGraph();
    assert (register_package(graph, "root", "1") == True);
    assert (register_package(graph, "left", "1") == True);
    assert (register_package(graph, "right", "1") == True);
    assert (register_package(graph, "shared", "1") == True);
    assert (register_package(graph, "deep", "1") == True);
    assert (register_package(graph, "tail", "1") == True);
    assert (add_dependency(graph, "root", "left") == True);
    assert (add_dependency(graph, "root", "right") == True);
    assert (add_dependency(graph, "left", "shared") == True);
    assert (add_dependency(graph, "left", "deep") == True);
    assert (add_dependency(graph, "right", "shared") == True);
    assert (add_dependency(graph, "shared", "tail") == True);
    assert (add_dependency(graph, "tail", "root") == True);
    assert (resolve_closure(graph, "root") == ["deep", "left", "right", "root", "shared", "tail"]);
}

test "unknown identifiers are tolerated" {
    graph = DependencyGraph();
    assert (resolve_closure(graph, "ghost") == []);
    assert (add_dependency(graph, "ghost", "other") == False);
    assert (validate_resolution(graph, ["ghost"]) == ["missing:ghost->other", "unknown:ghost"]);
}

test "duplicate versions report a conflict" {
    graph = DependencyGraph();
    assert (register_package(graph, "tool", "1.0") == True);
    assert (register_package(graph, "tool", "1.0") == True);
    assert (register_package(graph, "tool", "2.0") == False);
    assert (validate_resolution(graph, ["tool"]) == ["version:tool"]);
}

test "isolated and duplicate edges remain well-defined" {
    graph = DependencyGraph();
    assert (register_package(graph, "a", "1") == True);
    assert (register_package(graph, "b", "1") == True);
    assert (register_package(graph, "isolated", "1") == True);
    assert (add_dependency(graph, "a", "b") == True);
    assert (add_dependency(graph, "a", "b") == True);
    assert (resolve_closure(graph, "a") == ["a", "b"]);
    assert (validate_resolution(graph, ["a"]) == []);
}
