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
