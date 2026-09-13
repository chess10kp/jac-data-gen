"""CycloneDX/cyclonedx-dotnet#1126"""

node Package {
    has name: str;
    has direct_reference: bool = False;
    has excluded: bool = False;
}

edge Depends {}

obj PackageGraph {
    has packages: list[Package] = [];
}

walker Reachable {
    has claimed: dict[str, bool] = {};
    has found: list[Package] = [];

    can step with Package entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        if here.excluded == False {
            self.found.append(here);
            print(here.name);
            for kid in [here ->:Depends:->][?:Package] {
                visit :0: [kid];
            }
        }
    }
}

def new_graph() -> PackageGraph {
    return PackageGraph();
}

def add_package(
    graph: PackageGraph,
    name: str,
    direct_reference: bool = False
) -> Package {
    pkg = Package(name=name, direct_reference=direct_reference);
    graph.packages.append(pkg);
    return pkg;
}

def add_dependency(parent: Package, child: Package) {
    parent +>:Depends:+> child;
}

def mark_direct_references(graph: PackageGraph, names: list[str]) {
    for wanted in names {
        for pkg in graph.packages {
            if pkg.name == wanted {
                pkg.direct_reference = True;
            }
        }
    }
}

def exclude_packages(graph: PackageGraph, filter_name: str) {
    kept: list[Package] = [];
    for pkg in graph.packages {
        if pkg.name == filter_name {
            pkg.excluded = True;
        } else {
            kept.append(pkg);
        }
    }
    graph.packages = kept;
}

def remove_orphaned_packages(graph: PackageGraph) {
    reachable: dict[str, bool] = {};
    for pkg in graph.packages {
        if pkg.direct_reference == True {
            if pkg.excluded == False {
                w = pkg spawn Reachable(claimed={});
                for hit in w.found {
                    reachable[hit.name] = True;
                }
            }
        }
    }

    kept: list[Package] = [];
    for pkg in graph.packages {
        if pkg.excluded == False {
            if pkg.name in reachable {
                kept.append(pkg);
            }
        }
    }
    graph.packages = kept;
}

def package_names(graph: PackageGraph) -> list[str] {
    names: list[str] = [];
    for pkg in graph.packages {
        names.append(pkg.name);
    }
    return names;
}

test "diamond_revisit_keeps_complete_closure" {
    graph = new_graph();
    root_node = add_package(graph, "root", True);
    left = add_package(graph, "left");
    right = add_package(graph, "right");
    shared = add_package(graph, "shared");
    tail = add_package(graph, "tail");

    add_dependency(root_node, left);
    add_dependency(root_node, right);
    add_dependency(left, shared);
    add_dependency(right, shared);
    add_dependency(shared, tail);

    remove_orphaned_packages(graph);
    assert (sorted(package_names(graph)) == ["left", "right", "root", "shared", "tail"]);
}

test "unknown_filter_preserves_single_project_graph" {
    graph = new_graph();
    app = add_package(graph, "app");
    library = add_package(graph, "library");
    transitive = add_package(graph, "transitive");
    add_dependency(app, library);
    add_dependency(library, transitive);

    mark_direct_references(graph, ["app"]);
    exclude_packages(graph, "PackageThatDoesNotExist");
    remove_orphaned_packages(graph);

    assert (sorted(package_names(graph)) == ["app", "library", "transitive"]);
}

test "excluded_package_removes_only_its_cascade" {
    graph = new_graph();
    root_node = add_package(graph, "root", True);
    service = add_package(graph, "service");
    transitive = add_package(graph, "transitive");
    keep = add_package(graph, "keep");

    add_dependency(root_node, service);
    add_dependency(service, transitive);
    add_dependency(root_node, keep);

    exclude_packages(graph, "service");
    remove_orphaned_packages(graph);

    assert (sorted(package_names(graph)) == ["keep", "root"]);
}

test "cycle_revisit_does_not_truncate_walk" {
    graph = new_graph();
    root_node = add_package(graph, "root", True);
    first = add_package(graph, "first");
    second = add_package(graph, "second");

    add_dependency(root_node, first);
    add_dependency(first, second);
    add_dependency(second, root_node);

    exclude_packages(graph, "missing");
    remove_orphaned_packages(graph);

    assert (sorted(package_names(graph)) == ["first", "root", "second"]);
}

test "empty_graph_is_tolerated" {
    graph = new_graph();
    remove_orphaned_packages(graph);
    assert (package_names(graph) == []);
}
