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
