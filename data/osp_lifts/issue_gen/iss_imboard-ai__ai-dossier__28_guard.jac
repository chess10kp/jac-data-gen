"""imboard-ai/ai-dossier#28 — standalone cross-platform CLI binaries."""

node BuildPlan {
    has name: str;
}

node Platform {
    has os_name: str;
    has arch: str;
    has extension: str = "";
}

node Step {
    has name: str;
    has kind: str;
}

edge targets {}
edge entrypoint {}
edge depends_on {}

walker DependencyWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can begin with BuildPlan entry {
        print here.name;
        for first in [here ->:entrypoint:->][?:Step] {
            visit :0: [first];
        }
    }

    can step with Step entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.order.append(here.name);
        print here.name;
        for dependency in [here ->:depends_on:->][?:Step] {
            visit :0: [dependency];
        }
    }
}

def target_key(target: Platform) -> str {
    return target.os_name + "-" + target.arch;
}

def binary_name(target: Platform) -> str {
    return "dossier-verify-" + target_key(target) + target.extension;
}

def target_matrix() -> list[Platform] {
    targets: list[Platform] = [];
    targets.append(Platform(os_name="macos", arch="x64"));
    targets.append(Platform(os_name="macos", arch="arm64"));
    targets.append(Platform(os_name="linux", arch="x64"));
    targets.append(Platform(os_name="linux", arch="arm64"));
    targets.append(Platform(os_name="windows", arch="x64", extension=".exe"));
    return targets;
}

def create_release_plan() -> BuildPlan {
    graph_root = BuildPlan(name="dossier-release");
    for target in target_matrix() {
        graph_root +>:targets:+> target;
    }

    checkout = Step(name="checkout", kind="source");
    install = Step(name="install", kind="dependencies");
    package = Step(name="package", kind="standalone-binary");
    upload = Step(name="upload", kind="release");

    install +>:depends_on:+> checkout;
    package +>:depends_on:+> install;
    upload +>:depends_on:+> package;
    graph_root +>:entrypoint:+> upload;

    for target in [graph_root ->:targets:->][?:Platform] {
        package +>:targets:+> target;
    }
    return graph_root;
}

def artifact_names(graph_root: BuildPlan) -> list[str] {
    names: list[str] = [];
    for target in [graph_root ->:targets:->][?:Platform] {
        names.append(binary_name(target));
    }
    return sorted(names);
}

def target_exists(graph_root: BuildPlan, requested: str) -> bool {
    found = False;
    for target in [graph_root ->:targets:->][?:Platform] {
        if target_key(target) == requested {
            found = True;
        }
    }
    return found;
}

def dependency_order(graph_root: BuildPlan) -> list[str] {
    w = graph_root spawn DependencyWalker(claimed={});
    return w.order;
}

test "artifact matrix is deterministic" {
    graph_root = create_release_plan();
    assert (artifact_names(graph_root) == [
        "dossier-verify-linux-arm64",
        "dossier-verify-linux-x64",
        "dossier-verify-macos-arm64",
        "dossier-verify-macos-x64",
        "dossier-verify-windows-x64.exe"
    ]);
}

test "unknown target is tolerated" {
    graph_root = create_release_plan();
    assert (target_exists(graph_root, "linux-arm64") == True);
    assert (target_exists(graph_root, "plan9-x64") == False);
}

test "diamond revisit is claimed once" {
    graph_root = BuildPlan(name="diamond");
    upload = Step(name="upload", kind="release");
    linux = Step(name="package-linux", kind="binary");
    macos = Step(name="package-macos", kind="binary");
    install = Step(name="install", kind="dependencies");

    graph_root +>:entrypoint:+> upload;
    upload +>:depends_on:+> linux;
    upload +>:depends_on:+> macos;
    linux +>:depends_on:+> install;
    macos +>:depends_on:+> install;

    assert (sorted(dependency_order(graph_root)) == [
        "install",
        "package-linux",
        "package-macos",
        "upload"
    ]);
}

test "cyclic dependencies terminate" {
    graph_root = BuildPlan(name="cycle");
    first = Step(name="first", kind="build");
    second = Step(name="second", kind="build");
    third = Step(name="third", kind="build");

    graph_root +>:entrypoint:+> first;
    first +>:depends_on:+> second;
    second +>:depends_on:+> third;
    third +>:depends_on:+> first;

    assert (sorted(dependency_order(graph_root)) == [
        "first",
        "second",
        "third"
    ]);
}

test "empty plan has empty dependency order" {
    graph_root = BuildPlan(name="empty");
    assert (dependency_order(graph_root) == []);
    assert (artifact_names(graph_root) == []);
}
