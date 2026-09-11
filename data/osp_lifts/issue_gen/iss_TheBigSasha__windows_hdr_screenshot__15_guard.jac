"""Packaging dependency DAG and install-workflow reachability for hdrshot.

TheBigSasha/windows_hdr_screenshot#15 — pyproject/requirements drift,
optional gui/heic extras, fragile run.bat sentinel chain, bundle closure.
"""

node Package {
    has name: str;
}

node Step {
    has name: str;
}

edge Depends {}
edge Follows {}

walker DepClosure {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with Package entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.origin {
            self.found.append(here.name);
        }
        nbrs = [here ->:Depends:->][?:Package];
        nms: list[str] = [];
        for n in nbrs { nms.append(n.name); }
        for nm in sorted(nms) {
            for n in nbrs {
                if n.name == nm and n.name not in self.claimed { visit [n]; }
            }
        }
    }
}

walker PkgReach {
    has goal: str = "";
    has claimed: dict[str, bool] = {};
    has hit: bool = False;

    can step with Package entry {
        if here.name == self.goal {
            self.hit = True;
            disengage;
        }
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        visit [->:Depends:->][?:Package];
    }
}

walker StepReach {
    has goal: str = "";
    has claimed: dict[str, bool] = {};
    has hit: bool = False;

    can step with Step entry {
        if here.name == self.goal {
            self.hit = True;
            disengage;
        }
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        visit [->:Follows:->][?:Step];
    }
}

walker DepPathWalk {
    has target: str = "";
    has max_depth: int = 12;
    has trail: list[str] = [];
    has paths: list[list[str]] = [];

    can step with Package entry {
        if here.name in self.trail { skip; }
        nt: list[str] = [];
        for x in self.trail { nt.append(x); }
        nt.append(here.name);
        if here.name == self.target {
            row: list[str] = [];
            for x in nt { row.append(x); }
            self.paths.append(row);
            skip;
        }
        if len(nt) >= self.max_depth { skip; }
        kids = [here ->:Depends:->][?:Package];
        nms: list[str] = [];
        for n in kids { nms.append(n.name); }
        for nm in sorted(nms) {
            for n in kids {
                if n.name == nm {
                    n spawn DepPathWalk(
                        target=self.target,
                        max_depth=self.max_depth,
                        trail=nt,
                        paths=self.paths,
                    );
                }
            }
        }
    }
}

def _lookup_package(name: str) -> Package | None {
    for nd in [root -->][?:Package] {
        if nd.name == name { return nd; }
    }
    return None;
}

def _lookup_step(name: str) -> Step | None {
    for nd in [root -->][?:Step] {
        if nd.name == name { return nd; }
    }
    return None;
}

def _dep_edge_exists(src: Package, dst_name: str) -> bool {
    for n in [src ->:Depends:->][?:Package] {
        if n.name == dst_name { return True; }
    }
    return False;
}

def _step_edge_exists(src: Step, dst_name: str) -> bool {
    for n in [src ->:Follows:->][?:Step] {
        if n.name == dst_name { return True; }
    }
    return False;
}

def _sync_dep_graph(adj: dict[str, list[str]]) -> dict[str, Package] {
    nodes: dict[str, Package] = {};
    for nd in [root -->][?:Package] {
        if nd.name in adj { nodes[nd.name] = nd; }
    }
    for k in adj.keys() {
        if k not in nodes {
            nd = Package(name=k);
            root ++> nd;
            nodes[k] = nd;
        }
    }
    for (src, deps) in adj.items() {
        s = nodes.get(src, None);
        if s is None { continue; }
        for d in deps {
            t = nodes.get(d, None);
            if t is not None and not _dep_edge_exists(s, d) {
                s +>:Depends:+> t;
            }
        }
    }
    return nodes;
}

def _sync_step_graph(adj: dict[str, list[str]]) -> dict[str, Step] {
    nodes: dict[str, Step] = {};
    for nd in [root -->][?:Step] {
        if nd.name in adj { nodes[nd.name] = nd; }
    }
    for k in adj.keys() {
        if k not in nodes {
            nd = Step(name=k);
            root ++> nd;
            nodes[k] = nd;
        }
    }
    for (src, outs) in adj.items() {
        s = nodes.get(src, None);
        if s is None { continue; }
        for d in outs {
            t = nodes.get(d, None);
            if t is not None and not _step_edge_exists(s, d) {
                s +>:Follows:+> t;
            }
        }
    }
    return nodes;
}

def _use_step_graph(adj: dict[str, list[str]]) -> bool {
    for k in adj.keys() {
        if _lookup_step(k) is not None { return True; }
    }
    if "bundle" in adj or "hdrshot" in adj or "numpy" in adj { return False; }
    if "launch_gui" in adj or "install_sentinel" in adj { return True; }
    return False;
}

def build_dep_graph(packages: list[str], depends: list[tuple[str, str]]) -> dict[str, list[str]] {
    adj: dict[str, list[str]] = {};
    for p in packages { adj[p] = []; }
    for (pkg, dep) in depends {
        if pkg in adj and dep in adj { adj[pkg].append(dep); }
    }
    _sync_dep_graph(adj);
    return adj;
}

def transitive_deps(adj: dict[str, list[str]], `root: str) -> list[str] {
    if `root not in adj { return []; }
    nodes = _sync_dep_graph(adj);
    nd = nodes.get(`root, None);
    if nd is None { return []; }
    w = nd spawn DepClosure(claimed={}, found=[], origin=`root);
    return sorted(w.found);
}

def build_workflow(steps: list[str], transitions: list[tuple[str, str]]) -> dict[str, list[str]] {
    adj: dict[str, list[str]] = {};
    for s in steps { adj[s] = []; }
    for (src, dst) in transitions {
        if src in adj and dst in adj { adj[src].append(dst); }
    }
    _sync_step_graph(adj);
    return adj;
}

def is_reachable(adj: dict[str, list[str]], start: str, goal: str) -> bool {
    if start not in adj or goal not in adj { return False; }
    if _use_step_graph(adj) {
        step_nodes = _sync_step_graph(adj);
        st = step_nodes.get(start, None);
        if st is None { return False; }
        sw = st spawn StepReach(goal=goal, claimed={}, hit=False);
        return sw.hit;
    }
    pkg_nodes = _sync_dep_graph(adj);
    nd = pkg_nodes.get(start, None);
    if nd is None { return False; }
    pw = nd spawn PkgReach(goal=goal, claimed={}, hit=False);
    return pw.hit;
}

def paths_between(
    adj: dict[str, list[str]],
    source: str,
    target: str,
    max_depth: int = 12,
) -> list[list[str]] {
    if source not in adj or target not in adj { return []; }
    nodes = _sync_dep_graph(adj);
    nd = nodes.get(source, None);
    if nd is None { return []; }
    w = nd spawn DepPathWalk(
        target=target,
        max_depth=max_depth,
        trail=[],
        paths=[],
    );
    out: list[list[str]] = [];
    for p in w.paths {
        row: list[str] = [];
        for x in p { row.append(x); }
        out.append(row);
    }
    return sorted(out);
}

def version_drift(declarations: dict[str, dict[str, str]]) -> list[str] {
    merged: dict[str, dict[str, bool]] = {};
    keys: list[str] = [];
    for k in declarations.keys() { keys.append(k); }
    keys.sort();
    for source in keys {
        dec = declarations[source];
        for (pkg, ver) in dec.items() {
            if pkg not in merged { merged[pkg] = {}; }
            merged[pkg][ver] = True;
        }
    }
    out: list[str] = [];
    for (pkg, vers) in merged.items() {
        cnt = 0;
        for _ in vers.keys() { cnt += 1; }
        if cnt > 1 { out.append(pkg); }
    }
    return sorted(out);
}

def launch_allowed(
    workflow: dict[str, list[str]],
    completed: object,
    launch_step: str = "launch_gui",
) -> bool {
    if launch_step not in workflow { return False; }
    if not ("install_sentinel" in completed) { return False; }
    preds: list[str] = [];
    for a in workflow.keys() {
        if launch_step in workflow[a] { preds.append(a); }
    }
    for p in preds {
        if not (p in completed) { return False; }
    }
    return True;
}

test "diamond revisit transitive closure is duplicate-free" {
    pkgs = ["hdrshot", "numpy", "pillow", "bundle"];
    deps = [
        ("hdrshot", "numpy"),
        ("hdrshot", "pillow"),
        ("numpy", "bundle"),
        ("pillow", "bundle"),
    ];
    adj = build_dep_graph(pkgs, deps);
    assert transitive_deps(adj, "hdrshot") == ["bundle", "numpy", "pillow"];
    assert transitive_deps(adj, "bundle") == [];
}

test "cyclic depends terminates via claim skip not infinite revisit" {
    pkgs = ["a", "b", "c"];
    deps = [("a", "b"), ("b", "c"), ("c", "b")];
    adj = build_dep_graph(pkgs, deps);
    assert transitive_deps(adj, "a") == ["b", "c"];
    assert is_reachable(adj, "a", "c") == True;
    assert is_reachable(adj, "c", "a") == False;
}

test "paths_between diamond sorted and max_depth cutoff" {
    pkgs = ["a", "b", "c", "d"];
    deps = [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")];
    adj = build_dep_graph(pkgs, deps);
    assert paths_between(adj, "a", "d") == [["a", "b", "d"], ["a", "c", "d"]];
    assert paths_between(adj, "a", "d", max_depth=2) == [];
    assert paths_between(adj, "a", "d", max_depth=3) == [["a", "b", "d"], ["a", "c", "d"]];
}

test "launch_allowed sentinel gate" {
    wf = build_workflow(
        ["install_sentinel", "launch_gui"],
        [("install_sentinel", "launch_gui")],
    );
    assert launch_allowed(wf, ["install_sentinel"]) == True;
    assert launch_allowed(wf, []) == False;
}
