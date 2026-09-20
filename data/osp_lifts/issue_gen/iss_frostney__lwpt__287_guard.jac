"""frostney/lwpt#287 — dev-dependencies local resolver graph."""

node Package {
    has pid: str;
}

edge Depends {}
edge DevDepends {}

def copy_dict(src: dict[str, str]) -> dict[str, str] {
    out: dict[str, str] = {};
    for k in src {
        out[k] = src[k];
    }
    return out;
}

def drop_key_insensitive(d: dict[str, str], name: str) -> dict[str, str] {
    out: dict[str, str] = {};
    for k in d {
        if k.lower() != name.lower() {
            out[k] = d[k];
        }
    }
    return out;
}

def names_conflict(runtime: dict[str, str], dev: dict[str, str]) -> bool {
    seen: dict[str, bool] = {};
    for k in runtime {
        key = k.lower();
        if key in seen {
            return True;
        }
        seen[key] = True;
    }
    for k in dev {
        key = k.lower();
        if key in seen {
            return True;
        }
        seen[key] = True;
    }
    return False;
}

def dependency_section(runtime: dict[str, str], dev: dict[str, str], name: str) -> str | None {
    for k in runtime {
        if k.lower() == name.lower() {
            return "runtime";
        }
    }
    for k in dev {
        if k.lower() == name.lower() {
            return "dev";
        }
    }
    return None;
}

def add_dependency(
    runtime: dict[str, str],
    dev: dict[str, str],
    name: str,
    source: str,
    is_dev: bool,
) -> tuple[dict[str, str], dict[str, str]] {
    rt = drop_key_insensitive(runtime, name);
    dv = drop_key_insensitive(dev, name);
    if is_dev {
        dv[name] = source;
    } else {
        rt[name] = source;
    }
    return (rt, dv);
}

def remove_dependency(
    runtime: dict[str, str],
    dev: dict[str, str],
    name: str,
) -> tuple[dict[str, str], dict[str, str], str | None] {
    sec = dependency_section(runtime, dev, name);
    if sec is None {
        return (runtime, dev, None);
    }
    if sec == "runtime" {
        return (drop_key_insensitive(runtime, name), dev, sec);
    }
    return (runtime, drop_key_insensitive(dev, name), sec);
}

def pkg(pid: str) -> Package {
    p = Package(pid=pid);
    root ++> p;
    return p;
}

def link_runtime(src: Package, dst: Package) {
    src +>:Depends:+> dst;
}

def link_dev(src: Package, dst: Package) {
    src +>:DevDepends:+> dst;
}

walker ResolveWalker {
    has claimed: dict[str, bool] = {};
    has workspaces: dict[str, bool] = {};
    has order: list[str] = [];
    has start: Package;

    can launch with Root entry {
        visit :0: [self.start];
    }

    can walk_pkg with Package entry {
        if here.pid in self.claimed {
            skip;
        }
        self.claimed[here.pid] = True;
        self.order.append(here.pid);
        print("visit", here.pid);
        kids: list[Package] = [];
        for ch in [here ->:Depends:->][?:Package] {
            kids.append(ch);
        }
        if here.pid in self.workspaces {
            for ch in [here ->:DevDepends:->][?:Package] {
                kids.insert(0, ch);
            }
        }
        visit :0: kids;
    }
}

def resolve_local(start: Package, workspace_ids: list[str]) -> list[str] {
    ws: dict[str, bool] = {};
    for wid in workspace_ids {
        ws[wid] = True;
    }
    w = root spawn ResolveWalker(
        claimed={},
        workspaces=ws,
        order=[],
        start=start,
    );
    return w.order;
}

with entry {
    graph_root = pkg("root");
    ws_pkg = pkg("ws");
    lib_pkg = pkg("lib");
    test_pkg = pkg("testing");
    shared_pkg = pkg("shared");
    link_runtime(graph_root, ws_pkg);
    link_dev(ws_pkg, test_pkg);
    link_runtime(lib_pkg, shared_pkg);
    link_dev(lib_pkg, test_pkg);
    link_runtime(ws_pkg, lib_pkg);
    order = resolve_local(graph_root, ["root", "ws"]);
    print("demo", order);
}

test "dependency_section_runtime" {
    rt: dict[str, str] = {"Foo": "1.0"};
    dv: dict[str, str] = {"Bar": "2.0"};
    assert dependency_section(rt, dv, "foo") == "runtime";
}

test "add_remove_dev_dependency" {
    rt: dict[str, str] = {"A": "1"};
    dv: dict[str, str] = {};
    rt2: dict[str, str] = {};
    dv2: dict[str, str] = {};
    (rt2, dv2) = add_dependency(rt, dv, "Lint", "workspace:*", True);
    assert dv2["Lint"] == "workspace:*";
    (rt3, dv3, sec) = remove_dependency(rt2, dv2, "lint");
    assert sec == "dev";
    assert dependency_section(rt3, dv3, "Lint") is None;
}

test "names_conflict_case_insensitive" {
    rt: dict[str, str] = {"Pkg": "1"};
    dv: dict[str, str] = {"pkg": "2"};
    assert names_conflict(rt, dv) is True;
}

test "resolve_local_workspace_dev_first" {
    graph_root = pkg("root");
    ws_pkg = pkg("ws");
    lib_pkg = pkg("lib");
    test_pkg = pkg("testing");
    shared_pkg = pkg("shared");
    link_runtime(graph_root, ws_pkg);
    link_dev(ws_pkg, test_pkg);
    link_runtime(lib_pkg, shared_pkg);
    link_dev(lib_pkg, test_pkg);
    link_runtime(ws_pkg, lib_pkg);
    order = resolve_local(graph_root, ["root", "ws"]);
    assert order == ["root", "ws", "testing", "lib", "shared"];
}

test "resolve_local_skips_non_workspace_dev" {
    graph_root = pkg("root2");
    ws_pkg = pkg("ws2");
    lib_pkg = pkg("lib2");
    test_pkg = pkg("testing2");
    link_runtime(graph_root, ws_pkg);
    link_dev(ws_pkg, test_pkg);
    link_runtime(ws_pkg, lib_pkg);
    link_dev(lib_pkg, test_pkg);
    order = resolve_local(graph_root, ["root2"]);
    assert order == ["root2", "ws2", "lib2"];
}

test "resolve_local_cycle_skip" {
    a = pkg("a");
    b = pkg("b");
    link_runtime(a, b);
    link_runtime(b, a);
    order = resolve_local(a, ["a"]);
    assert order == ["a", "b"];
}
