"""BreachSAFE/qureddy#37 — release-candidate roadmap graph."""

node Task {
    has task_id: str;
    has title: str;
    has status: str = "open";
}

node Package {
    has package_id: str;
    has digest: str = "";
    has built: bool = False;
}

edge Depends {}
edge References {}
edge Lineage {}
edge Builds {}

obj Roadmap {
    has tasks: dict[str, Task] = {};
    has packages: dict[str, Package] = {};
}

walker DependencyWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can step with Task entry {
        if here.task_id in self.claimed { skip; }
        self.claimed[here.task_id] = True;
        self.found.append(here.task_id);
        print("depends:" + here.task_id);
        for child in [here ->:Depends:->][?:Task] {
            visit :0: [child];
        }
    }
}

walker ReferenceWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can step with Task entry {
        if here.task_id in self.claimed { skip; }
        self.claimed[here.task_id] = True;
        self.found.append(here.task_id);
        print("reference:" + here.task_id);
        for child in [here ->:References:->][?:Task] {
            visit :0: [child];
        }
    }
}

walker LineageWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can step with Task entry {
        if here.task_id in self.claimed { skip; }
        self.claimed[here.task_id] = True;
        self.found.append(here.task_id);
        print("lineage:" + here.task_id);
        for child in [here ->:Lineage:->][?:Task] {
            visit :0: [child];
        }
    }
}

def create_roadmap() -> Roadmap {
    return Roadmap();
}

def add_task(board: Roadmap, task_id: str, title: str, status: str = "open") -> bool {
    if task_id in board.tasks { return False; }
    task = Task(task_id=task_id, title=title, status=status);
    board.tasks[task_id] = task;
    return True;
}

def add_dependency(board: Roadmap, source_id: str, target_id: str) -> bool {
    if source_id not in board.tasks { return False; }
    if target_id not in board.tasks { return False; }
    source = board.tasks[source_id];
    target = board.tasks[target_id];
    source +>:Depends:+> target;
    return True;
}

def add_reference(board: Roadmap, source_id: str, target_id: str) -> bool {
    if source_id not in board.tasks { return False; }
    if target_id not in board.tasks { return False; }
    source = board.tasks[source_id];
    target = board.tasks[target_id];
    source +>:References:+> target;
    return True;
}

def task_closure(board: Roadmap, task_id: str) -> list[str] {
    if task_id not in board.tasks { return []; }
    w = board.tasks[task_id] spawn DependencyWalker(claimed={});
    return sorted(w.found);
}

def reference_reach(board: Roadmap, task_id: str) -> list[str] {
    if task_id not in board.tasks { return []; }
    w = board.tasks[task_id] spawn ReferenceWalker(claimed={});
    return sorted(w.found);
}

def add_package(board: Roadmap, package_id: str) -> bool {
    if package_id in board.packages { return False; }
    package = Package(package_id=package_id);
    board.packages[package_id] = package;
    return True;
}

def build_package(board: Roadmap, package_id: str, task_id: str, digest: str) -> bool {
    if package_id not in board.packages { return False; }
    if task_id not in board.tasks { return False; }
    package = board.packages[package_id];
    task = board.tasks[task_id];
    package.digest = digest;
    package.built = True;
    task +>:Builds:+> package;
    return True;
}

def release_ready(board: Roadmap, task_id: str, package_id: str) -> bool {
    if task_id not in board.tasks { return False; }
    if package_id not in board.packages { return False; }
    w = board.tasks[task_id] spawn DependencyWalker(claimed={});
    for found_id in w.found {
        if board.tasks[found_id].status != "done" { return False; }
    }
    return board.packages[package_id].built;
}

def link_lineage(board: Roadmap, newer_id: str, older_id: str) -> bool {
    if newer_id not in board.tasks { return False; }
    if older_id not in board.tasks { return False; }
    newer = board.tasks[newer_id];
    older = board.tasks[older_id];
    newer +>:Lineage:+> older;
    return True;
}

def lineage_path(board: Roadmap, task_id: str) -> list[str] {
    if task_id not in board.tasks { return []; }
    w = board.tasks[task_id] spawn LineageWalker(claimed={});
    return w.found;
}

test "diamond dependency closure claims once" {
    board = create_roadmap();
    assert (add_task(board, "a", "release", "done"));
    assert (add_task(board, "b", "build", "done"));
    assert (add_task(board, "c", "tests", "done"));
    assert (add_task(board, "d", "package", "done"));
    assert (add_dependency(board, "a", "b"));
    assert (add_dependency(board, "a", "c"));
    assert (add_dependency(board, "b", "d"));
    assert (add_dependency(board, "c", "d"));
    assert (add_dependency(board, "d", "a"));
    assert (task_closure(board, "a") == ["a", "b", "c", "d"]);
}

test "unknown identifiers are tolerated" {
    board = create_roadmap();
    assert (task_closure(board, "missing") == []);
    assert (reference_reach(board, "missing") == []);
    assert (lineage_path(board, "missing") == []);
    assert (add_dependency(board, "missing", "x") == False);
    assert (add_reference(board, "missing", "x") == False);
    assert (link_lineage(board, "missing", "x") == False);
    assert (build_package(board, "missing", "x", "sha256:x") == False);
    assert (release_ready(board, "missing", "missing") == False);
}

test "package build gates release readiness" {
    board = create_roadmap();
    assert (add_task(board, "rc", "release candidate", "done"));
    assert (add_task(board, "blocker", "pending check"));
    assert (add_package(board, "qureddy"));
    assert (build_package(board, "qureddy", "rc", "sha256:abc"));
    assert (release_ready(board, "rc", "qureddy"));
    assert (add_dependency(board, "rc", "blocker"));
    assert (release_ready(board, "rc", "qureddy") == False);
}

test "references and lineage preserve reachable paths" {
    board = create_roadmap();
    assert (add_task(board, "release", "current", "done"));
    assert (add_task(board, "source", "previous", "done"));
    assert (add_reference(board, "release", "source"));
    assert (link_lineage(board, "release", "source"));
    assert (reference_reach(board, "release") == ["release", "source"]);
    assert (lineage_path(board, "release") == ["release", "source"]);
}

test "duplicate records are rejected" {
    board = create_roadmap();
    assert (add_task(board, "same", "", "open"));
    assert (add_task(board, "same", "replacement", "done") == False);
    assert (add_package(board, "pkg"));
    assert (add_package(board, "pkg") == False);
}
