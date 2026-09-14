"""Idiomatic OSP lift for frostney/lwpt#287."""

node Project {
    has name: str;
    has development_root: bool = True;
    has regular: dict[str, str] = {};
    has development: dict[str, str] = {};
}

node Package {
    has name: str;
}

edge Runtime {}
edge Development {}
edge Workspace {}

def canonical(name: str) -> str {
    return name.lower();
}

def new_project(name: str, development_root: bool = True) -> Project {
    return Project(name=name, development_root=development_root);
}

def new_package(name: str) -> Package {
    return Package(name=name);
}

def attach_workspace(root_project: Project, workspace: Project) -> None {
    workspace.development_root = True;
    root_project +>:Workspace:+> workspace;
}

def attach_runtime(owner: Package, dependency: Package) -> None {
    owner +>:Runtime:+> dependency;
}

def manifest_add(project: Project, package: Package, source: str, dev: bool = False) -> None {
    key = canonical(package.name);
    if dev {
        if key in project.regular {
            del project.regular[key];
        }
        project.development[key] = source;
        project +>:Development:+> package;
    } else {
        if key in project.development {
            del project.development[key];
        }
        project.regular[key] = source;
        project +>:Runtime:+> package;
    }
}

def manifest_remove(project: Project, name: str) -> bool {
    key = canonical(name);
    if key in project.regular {
        del project.regular[key];
        return True;
    }
    if key in project.development {
        del project.development[key];
        return True;
    }
    return False;
}

walker ResolvePackages {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step_project with Project entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print(here.name);

        for workspace in [here ->:Workspace:->][?:Project] {
            visit :0: [workspace];
        }
        for package in [here ->:Runtime:->][?:Package] {
            if canonical(package.name) in here.regular {
                visit :0: [package];
            }
        }
        if here.development_root {
            for package in [here ->:Development:->][?:Package] {
                if canonical(package.name) in here.development {
                    visit :0: [package];
                }
            }
        }
    }

    can step_package with Package entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.name);
        print(here.name);

        for dependency in [here ->:Runtime:->][?:Package] {
            visit :0: [dependency];
        }
    }
}

def resolve_packages(root_project: Project) -> list[str] {
    w = root_project spawn ResolvePackages(claimed={});
    return sorted(w.found);
}

walker Demo {
    can start with entry {
        print("LWPT development dependency resolver");
    }
}

with entry {
    root spawn Demo;
}

test "diamond revisit is claimed once" {
    root_project = new_project("root");
    left = new_package("left");
    right = new_package("right");
    shared = new_package("shared");
    manifest_add(root_project, left, "owner/left@^1.0.0");
    manifest_add(root_project, right, "owner/right@^1.0.0");
    attach_runtime(left, shared);
    attach_runtime(right, shared);
    assert (resolve_packages(root_project) == ["left", "right", "shared"]);
}

test "workspace development dependencies are included" {
    root_project = new_project("root");
    workspace = new_project("tools");
    tool = new_package("testing");
    manifest_add(workspace, tool, "owner/testing@^1.0.0", True);
    attach_workspace(root_project, workspace);
    assert (resolve_packages(root_project) == ["testing"]);
}

test "transitive package development graph is regular only" {
    root_project = new_project("root");
    app = new_package("app");
    core = new_package("core");
    manifest_add(root_project, app, "owner/app@^1.0.0");
    attach_runtime(app, core);
    attach_runtime(core, app);
    assert (resolve_packages(root_project) == ["app", "core"]);
}

test "unknown removal is tolerated" {
    root_project = new_project("root");
    assert (manifest_remove(root_project, "missing") == False);
    assert (resolve_packages(root_project) == []);
}

test "readding moves a declaration between sections" {
    root_project = new_project("root");
    testing = new_package("testing");
    manifest_add(root_project, testing, "owner/testing@^1.0.0");
    manifest_add(root_project, testing, "owner/testing@^2.0.0", True);
    assert (manifest_remove(root_project, "testing") == True);
    assert (resolve_packages(root_project) == []);
}
