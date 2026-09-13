"""JoNil-Botta/typelisp#6982: propagate native link requirements."""

node Package {
    has package_id: str;
    has kind: str;
    has manifest_root: str;
}

node LinkNeed {
    has token: str;
    has target: str;
    has provenance: str;
}

edge Depends {}
edge Exports {}

def new_package(package_id: str, kind: str, manifest_root: str) -> Package {
    return Package(package_id=package_id, kind=kind, manifest_root=manifest_root);
}

def depends_on(source: Package, target: Package) -> None {
    source +>:Depends:+> target;
}

def declare_link(package: Package, value: str, target: str, kind: str, relative: bool) -> LinkNeed {
    token: str = value;
    if kind == "library" {
        token = "-l" + value;
    }
    if kind == "search" {
        if relative {
            token = "-L" + package.manifest_root + "/" + value;
        } else {
            token = "-L" + value;
        }
    }
    provenance: str = package.package_id + "@" + package.manifest_root + " => " + token;
    need = LinkNeed(token=token, target=target, provenance=provenance);
    package +>:Exports:+> need;
    return need;
}

walker LinkPlanWalker {
    has platform: str;
    has plan: list[str] = [];
    has explanations: list[str] = [];
    has claimed: dict[str, bool] = {};

    can collect with Package entry {
        if here.package_id in self.claimed {
            skip;
        }
        self.claimed[here.package_id] = True;
        print("link-plan: " + here.package_id);
        if here.kind == "binary" or here.kind == "staticlib" {
            for need in [here ->:Exports:->][?:LinkNeed] {
                if need.target == "all" or need.target == self.platform {
                    if need.token not in self.plan {
                        self.plan.append(need.token);
                        self.explanations.append(need.provenance);
                    }
                }
            }
        }
        for kid in [here ->:Depends:->][?:Package] {
            visit :0: [kid];
        }
    }
}

walker PackageFinder {
    has wanted: str;
    has found: Package | None = None;
    has claimed: dict[str, bool] = {};

    can find with Package entry {
        if here.package_id in self.claimed {
            skip;
        }
        self.claimed[here.package_id] = True;
        print("search: " + here.package_id);
        if here.package_id == self.wanted {
            self.found = here;
        }
        for kid in [here ->:Depends:->][?:Package] {
            visit :0: [kid];
        }
    }
}

def build_link_plan(graph_root: Package, platform: str) -> list[str] {
    w = graph_root spawn LinkPlanWalker(platform=platform, claimed={});
    return w.plan;
}

def explain_link_plan(graph_root: Package, platform: str) -> list[str] {
    w = graph_root spawn LinkPlanWalker(platform=platform, claimed={});
    return w.explanations;
}

def find_package(graph_root: Package, package_id: str) -> Package | None {
    w = graph_root spawn PackageFinder(wanted=package_id, claimed={});
    return w.found;
}
