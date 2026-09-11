#!/usr/bin/env python3
"""Generate all remaining OSP issue_gen records (issues_24 #4-10, issues_25 #1-10)."""
from pathlib import Path

IG = Path(__file__).resolve().parents[1] / "issue_gen"


def w(stem: str, py: str, ref_body: str, jac: str, tests: str) -> None:
    ref = f'''"""Reference harness for {stem}."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("{stem}.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
{ref_body}
print("{stem} ref OK")
'''
    IG.mkdir(exist_ok=True)
    (IG / f"{stem}.py").write_text(py)
    (IG / f"{stem}.ref.py").write_text(ref)
    (IG / f"{stem}.jac").write_text(jac)
    (IG / f"{stem}_guard.jac").write_text(jac.rstrip() + "\n\n" + tests.strip() + "\n")
    print(stem)


# --- issues_24 remaining ---

w(
    "iss_BeardedSheeep__assesment-socgen__4",
    '''"""BeardedSheeep/assesment-socgen#4 — Docker layer rebuild dependency graph."""

from collections import deque


class LayerGraph:
    def __init__(self) -> None:
        self._layers: set[str] = set()
        self._deps: dict[str, list[str]] = {}


def load_layers(layers: list[str], deps: list[tuple[str, str]]) -> LayerGraph:
    g = LayerGraph()
    for name in layers:
        g._layers.add(name)
        g._deps.setdefault(name, [])
    for base, upper in deps:
        if base in g._layers and upper in g._layers:
            g._deps.setdefault(upper, []).append(base)
    return g


def invalidated_by(store: LayerGraph, changed: str) -> list[str]:
    if changed not in store._layers:
        return []
    seen: set[str] = {changed}
    queue: deque[str] = deque([changed])
    out: set[str] = set()
    while queue:
        cur = queue.popleft()
        for name in store._layers:
            if cur in store._deps.get(name, []) and name not in seen:
                seen.add(name)
                out.add(name)
                queue.append(name)
    return sorted(out)
''',
    '''
g = _mod.load_layers(
    ["base", "deps", "app_copy", "final"],
    [("base", "deps"), ("deps", "app_copy"), ("app_copy", "final")],
)
assert _mod.invalidated_by(g, "deps") == ["app_copy", "final"]
''',
    '''"""BeardedSheeep/assesment-socgen#4 — Docker layer rebuild dependency graph."""

node Layer {
    has name: str;
}

edge DependsOn {}

obj LayerGraph {
    has layers: dict[str, Layer] = {};
}

def load_layers(layers: list[str], deps: list[tuple[str, str]]) -> LayerGraph {
    g = LayerGraph();
    for name in layers {
        nd = Layer(name=name);
        root ++> nd;
        g.layers[name] = nd;
    }
    for (base, upper) in deps {
        b = g.layers.get(base, None);
        u = g.layers.get(upper, None);
        if b is not None and u is not None { u +>:DependsOn:+> b; }
    }
    return g;
}

def invalidated_by(store: LayerGraph, changed: str) -> list[str] {
    if not (changed in store.layers) { return []; }
    seen: dict[str, bool] = {changed: True};
    frontier: list[str] = [changed];
    out: list[str] = [];
    while len(frontier) > 0 {
        cur = frontier.pop(0);
        for name in store.layers.keys() {
            nd = store.layers[name];
            dep_names: list[str] = [];
            for d in [nd ->:DependsOn:->][?:Layer] { dep_names.append(d.name); }
            if cur in dep_names and not (name in seen) {
                seen[name] = True;
                out.append(name);
                frontier.append(name);
            }
        }
    }
    out.sort();
    return out;
}
''',
    '''
test "layer invalidation" {
    g = load_layers(
        ["base", "deps", "app_copy", "final"],
        [("base", "deps"), ("deps", "app_copy"), ("app_copy", "final")],
    );
    assert invalidated_by(g, "deps") == ["app_copy", "final"];
}
''',
)

w(
    "iss_BharatDBPG__BharatDBMS-PG__3005",
    '''"""BharatDBPG/BharatDBMS-PG#3005 — recursive view traversal with level tracking."""

from collections import deque


class ViewGraph:
    def __init__(self) -> None:
        self._nodes: set[str] = set()
        self._edges: dict[str, list[str]] = {}


def load_view_graph(nodes: list[str], edges: list[tuple[str, str]]) -> ViewGraph:
    g = ViewGraph()
    for n in nodes:
        g._nodes.add(n)
        g._edges.setdefault(n, [])
    for a, b in edges:
        if a in g._nodes and b in g._nodes:
            g._edges.setdefault(a, []).append(b)
    return g


def reachable_with_levels(store: ViewGraph, start: str) -> dict[str, int]:
    if start not in store._nodes:
        return {}
    levels: dict[str, int] = {start: 0}
    queue: deque[str] = deque([start])
    while queue:
        cur = queue.popleft()
        for nxt in store._edges.get(cur, []):
            nl = levels[cur] + 1
            if nxt not in levels or nl < levels[nxt]:
                levels[nxt] = nl
                queue.append(nxt)
    return dict(levels)
''',
    '''
g = _mod.load_view_graph(
    ["root", "v1", "v2", "leaf"],
    [("root", "v1"), ("root", "v2"), ("v1", "leaf"), ("v2", "leaf")],
)
lv = _mod.reachable_with_levels(g, "root")
assert lv["leaf"] == 2
assert lv["root"] == 0
''',
    '''"""BharatDBPG/BharatDBMS-PG#3005 — recursive view traversal with level tracking."""

node ViewNode {
    has name: str;
}

edge LinksTo {}

obj ViewGraph {
    has nodes: dict[str, ViewNode] = {};
}

walker LevelWalk {
    has claimed: dict[str, bool] = {};
    has levels: dict[str, int] = {};
    has start_depth: int = 0;

    can step with ViewNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if not (here.name in self.levels) {
            self.levels[here.name] = self.start_depth;
        }
        visit [->:LinksTo:->][?:ViewNode] with LevelWalk(
            claimed=self.claimed,
            levels=self.levels,
            start_depth=self.levels[here.name] + 1,
        );
    }
}

def load_view_graph(nodes: list[str], edges: list[tuple[str, str]]) -> ViewGraph {
    g = ViewGraph();
    for n in nodes {
        nd = ViewNode(name=n);
        root ++> nd;
        g.nodes[n] = nd;
    }
    for (a, b) in edges {
        na = g.nodes.get(a, None);
        nb = g.nodes.get(b, None);
        if na is not None and nb is not None { na +>:LinksTo:+> nb; }
    }
    return g;
}

def reachable_with_levels(store: ViewGraph, start: str) -> dict[str, int] {
    nd = store.nodes.get(start, None);
    if nd is None { return {}; }
    w = nd spawn LevelWalk(claimed={}, levels={}, start_depth=0);
    return w.levels;
}
''',
    '''
test "view levels diamond" {
    g = load_view_graph(
        ["root", "v1", "v2", "leaf"],
        [("root", "v1"), ("root", "v2"), ("v1", "leaf"), ("v2", "leaf")],
    );
    lv = reachable_with_levels(g, "root");
    assert lv["leaf"] == 2;
    assert lv["root"] == 0;
}
''',
)

w(
    "iss_BootBlock__Gubbins__403",
    '''"""BootBlock/Gubbins#403 — issue triage priority parent-child tree."""


def load_issues(parents: dict[str, str | None]) -> dict:
    return {"parents": dict(parents)}


def _children(reg: dict, pid: str) -> list[str]:
    out = [cid for cid, p in reg["parents"].items() if p == pid]
    return sorted(out)


def subtree_issues(reg: dict, root: str) -> list[str]:
    if root not in reg["parents"]:
        return []
    seen: set[str] = set()
    stack = [root]
    out: list[str] = []
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        out.append(cur)
        for ch in _children(reg, cur):
            stack.append(ch)
    return sorted(out)
''',
    '''
reg = _mod.load_issues({"data-loss": None, "sync": "data-loss", "ui": "sync", "perf": "ui"})
assert _mod.subtree_issues(reg, "data-loss") == ["data-loss", "perf", "sync", "ui"]
''',
    '''"""BootBlock/Gubbins#403 — issue triage priority parent-child tree."""

node Issue {
    has iid: str;
}

edge ChildOf {}

obj IssueTree {
    has issues: dict[str, Issue] = {};
}

walker SubtreeWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Issue entry {
        if here.iid in self.claimed { skip; }
        self.claimed[here.iid] = True;
        self.reached.append(here.iid);
        visit [here <-:ChildOf:<-][?:Issue];
    }
}

def load_issues(parents: dict[str, str | None]) -> IssueTree {
    reg = IssueTree();
    for iid in parents.keys() {
        nd = Issue(iid=iid);
        root ++> nd;
        reg.issues[iid] = nd;
    }
    for iid in parents.keys() {
        p = parents[iid];
        if p is not None {
            pa = reg.issues.get(p, None);
            ch = reg.issues.get(iid, None);
            if pa is not None and ch is not None { ch +>:ChildOf:+> pa; }
        }
    }
    return reg;
}

def subtree_issues(reg: IssueTree, root: str) -> list[str] {
    nd = reg.issues.get(root, None);
    if nd is None { return []; }
    w = nd spawn SubtreeWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}
''',
    '''
test "triage subtree" {
    reg = load_issues({"data-loss": None, "sync": "data-loss", "ui": "sync", "perf": "ui"});
    assert subtree_issues(reg, "data-loss") == ["data-loss", "perf", "sync", "ui"];
}
''',
)

w(
    "iss_Chris-Wolfgang__repo-template__411",
    '''"""Chris-Wolfgang/repo-template#411 — transitive NuGet dependency walk."""

from collections import deque


class DepGraph:
    def __init__(self) -> None:
        self._pkgs: set[str] = set()
        self._deps: dict[str, list[str]] = {}


def load_packages(pkgs: list[str], edges: list[tuple[str, str]]) -> DepGraph:
    g = DepGraph()
    for p in pkgs:
        g._pkgs.add(p)
        g._deps.setdefault(p, [])
    for a, b in edges:
        if a in g._pkgs and b in g._pkgs:
            g._deps.setdefault(a, []).append(b)
    return g


def transitive_deps(store: DepGraph, pkg: str) -> list[str]:
    if pkg not in store._pkgs:
        return []
    seen: set[str] = {pkg}
    queue: deque[str] = deque([pkg])
    out: set[str] = set()
    while queue:
        cur = queue.popleft()
        for d in store._deps.get(cur, []):
            out.add(d)
            if d not in seen:
                seen.add(d)
                queue.append(d)
    return sorted(out)
''',
    '''
g = _mod.load_packages(
    ["app", "core", "json", "linq"],
    [("app", "core"), ("core", "json"), ("core", "linq")],
)
assert _mod.transitive_deps(g, "app") == ["core", "json", "linq"]
''',
    '''"""Chris-Wolfgang/repo-template#411 — transitive NuGet dependency walk."""

node Package {
    has name: str;
}

edge Requires {}

obj DepGraph {
    has pkgs: dict[str, Package] = {};
}

walker DepWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Package entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        for d in [here ->:Requires:->][?:Package] {
            if not (d.name in self.claimed) {
                self.found.append(d.name);
                visit [d];
            }
        }
    }
}

def load_packages(pkgs: list[str], edges: list[tuple[str, str]]) -> DepGraph {
    g = DepGraph();
    for p in pkgs {
        nd = Package(name=p);
        root ++> nd;
        g.pkgs[p] = nd;
    }
    for (a, b) in edges {
        pa = g.pkgs.get(a, None);
        pb = g.pkgs.get(b, None);
        if pa is not None and pb is not None { pa +>:Requires:+> pb; }
    }
    return g;
}

def transitive_deps(store: DepGraph, pkg: str) -> list[str] {
    nd = store.pkgs.get(pkg, None);
    if nd is None { return []; }
    w = nd spawn DepWalk(claimed={}, found=[]);
    return sorted(w.found);
}
''',
    '''
test "transitive deps" {
    g = load_packages(
        ["app", "core", "json", "linq"],
        [("app", "core"), ("core", "json"), ("core", "linq")],
    );
    assert transitive_deps(g, "app") == ["core", "json", "linq"];
}
''',
)

w(
    "iss_Concorda-Sailing__knowledge-graph__56",
    '''"""Concorda-Sailing/knowledge-graph#56 — dossier outbound dependency reach."""

from collections import deque


class DossierGraph:
    def __init__(self) -> None:
        self._nodes: set[str] = set()
        self._out: dict[str, list[str]] = {}


def load_dossiers(nodes: list[str], edges: list[tuple[str, str]]) -> DossierGraph:
    g = DossierGraph()
    for n in nodes:
        g._nodes.add(n)
        g._out.setdefault(n, [])
    for src, dst in edges:
        if src in g._nodes and dst in g._nodes:
            g._out.setdefault(src, []).append(dst)
    return g


def outbound_reach(store: DossierGraph, node: str) -> list[str]:
    if node not in store._nodes:
        return []
    seen: set[str] = {node}
    queue: deque[str] = deque([node])
    out: set[str] = set()
    while queue:
        cur = queue.popleft()
        for nxt in store._out.get(cur, []):
            out.add(nxt)
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(out)
''',
    '''
g = _mod.load_dossiers(
    ["fn_a", "fn_b", "cls_c", "mod_d"],
    [("fn_a", "fn_b"), ("fn_a", "cls_c"), ("fn_b", "mod_d")],
)
assert _mod.outbound_reach(g, "fn_a") == ["cls_c", "fn_b", "mod_d"]
''',
    '''"""Concorda-Sailing/knowledge-graph#56 — dossier outbound dependency reach."""

node Dossier {
    has name: str;
}

edge DependsOn {}

obj DossierGraph {
    has nodes: dict[str, Dossier] = {};
}

walker OutWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Dossier entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [->:DependsOn:->][?:Dossier];
    }
}

def load_dossiers(nodes: list[str], edges: list[tuple[str, str]]) -> DossierGraph {
    g = DossierGraph();
    for n in nodes {
        nd = Dossier(name=n);
        root ++> nd;
        g.nodes[n] = nd;
    }
    for (src, dst) in edges {
        s = g.nodes.get(src, None);
        d = g.nodes.get(dst, None);
        if s is not None and d is not None { s +>:DependsOn:+> d; }
    }
    return g;
}

def outbound_reach(store: DossierGraph, node: str) -> list[str] {
    nd = store.nodes.get(node, None);
    if nd is None { return []; }
    w = nd spawn OutWalk(claimed={}, reached=[]);
    out: list[str] = [];
    for n in w.reached {
        if n != node { out.append(n); }
    }
    return sorted(out);
}
''',
    '''
test "outbound reach" {
    g = load_dossiers(
        ["fn_a", "fn_b", "cls_c", "mod_d"],
        [("fn_a", "fn_b"), ("fn_a", "cls_c"), ("fn_b", "mod_d")],
    );
    assert outbound_reach(g, "fn_a") == ["cls_c", "fn_b", "mod_d"];
}
''',
)

w(
    "iss_DanielMSchmidt__cfast__305",
    '''"""DanielMSchmidt/cfast#305 — folder visibility inheritance parent walk."""


def load_folders(parents: dict[str, str | None], visibility: dict[str, str]) -> dict:
    return {"parents": dict(parents), "visibility": dict(visibility)}


def _walk_up(reg: dict, fid: str) -> list[str]:
    chain: list[str] = []
    cur: str | None = fid
    seen: set[str] = set()
    while cur is not None and cur in reg["parents"]:
        if cur in seen:
            break
        seen.add(cur)
        chain.append(cur)
        cur = reg["parents"][cur]
    return chain


def effective_visibility(reg: dict, folder: str) -> str:
    if folder not in reg["parents"]:
        return "restricted"
    for fid in _walk_up(reg, folder):
        vis = reg["visibility"].get(fid, "inherit")
        if vis != "inherit":
            return vis
    return "restricted"


def ancestor_folders(reg: dict, folder: str) -> list[str]:
    chain = _walk_up(reg, folder)
    return list(reversed(chain))
''',
    '''
reg = _mod.load_folders(
    {"root": None, "team": "root", "docs": "team"},
    {"root": "workspace", "team": "inherit", "docs": "inherit"},
)
assert _mod.effective_visibility(reg, "docs") == "workspace"
assert _mod.ancestor_folders(reg, "docs") == ["root", "team", "docs"]
''',
    '''"""DanielMSchmidt/cfast#305 — folder visibility inheritance parent walk."""

node Folder {
    has fid: str;
    has visibility: str = "inherit";
}

edge ParentOf {}

obj FolderTree {
    has folders: dict[str, Folder] = {};
}

walker UpWalk {
    has chain: list[str] = [];
    has claimed: dict[str, bool] = {};

    can step with Folder entry {
        if here.fid in self.claimed { disengage; }
        self.claimed[here.fid] = True;
        self.chain.append(here.fid);
        visit [here <-:ParentOf:<-] else { disengage; }
    }
}

def load_folders(parents: dict[str, str | None], visibility: dict[str, str]) -> FolderTree {
    reg = FolderTree();
    for fid in parents.keys() {
        nd = Folder(fid=fid, visibility=visibility.get(fid, "inherit"));
        root ++> nd;
        reg.folders[fid] = nd;
    }
    for fid in parents.keys() {
        p = parents[fid];
        if p is not None {
            pa = reg.folders.get(p, None);
            ch = reg.folders.get(fid, None);
            if pa is not None and ch is not None { pa +>:ParentOf:+> ch; }
        }
    }
    return reg;
}

def effective_visibility(reg: FolderTree, folder: str) -> str {
    nd = reg.folders.get(folder, None);
    if nd is None { return "restricted"; }
    w = nd spawn UpWalk();
    for fid in w.chain {
        vis = reg.folders[fid].visibility;
        if vis != "inherit" { return vis; }
    }
    return "restricted";
}

def ancestor_folders(reg: FolderTree, folder: str) -> list[str] {
    nd = reg.folders.get(folder, None);
    if nd is None { return []; }
    w = nd spawn UpWalk();
    rev: list[str] = [];
    for i in range(len(w.chain) - 1, -1, -1) { rev.append(w.chain[i]); }
    return rev;
}
''',
    '''
test "folder visibility inherit" {
    reg = load_folders(
        {"root": None, "team": "root", "docs": "team"},
        {"root": "workspace", "team": "inherit", "docs": "inherit"},
    );
    assert effective_visibility(reg, "docs") == "workspace";
    assert ancestor_folders(reg, "docs") == ["root", "team", "docs"];
}
''',
)

w(
    "iss_DonTizi__CodeGeass__2",
    '''"""DonTizi/CodeGeass#2 — task DAG cycle detection and ready frontier."""

from collections import deque


class TaskGraph:
    def __init__(self) -> None:
        self._tasks: set[str] = set()
        self._deps: dict[str, list[str]] = {}
        self._done: set[str] = set()


def load_tasks(tasks: list[str], edges: list[tuple[str, str]], done: list[str] | None = None) -> TaskGraph:
    g = TaskGraph()
    for t in tasks:
        g._tasks.add(t)
        g._deps.setdefault(t, [])
    for blocker, blocked in edges:
        if blocker in g._tasks and blocked in g._tasks:
            g._deps.setdefault(blocked, []).append(blocker)
    if done:
        g._done = set(done)
    return g


def has_cycle(store: TaskGraph) -> bool:
    state: dict[str, int] = {t: 0 for t in store._tasks}
    for start in sorted(store._tasks):
        if state[start] != 0:
            continue
        stack = [(start, 0)]
        while stack:
            node, idx = stack[-1]
            if idx == 0:
                if state[node] == 1:
                    return True
                if state[node] == 2:
                    stack.pop()
                    continue
                state[node] = 1
            deps = store._deps.get(node, [])
            if idx < len(deps):
                stack[-1] = (node, idx + 1)
                stack.append((deps[idx], 0))
            else:
                state[node] = 2
                stack.pop()
    return False


def ready_tasks(store: TaskGraph) -> list[str]:
    out: list[str] = []
    for t in sorted(store._tasks):
        if t in store._done:
            continue
        blockers = store._deps.get(t, [])
        if all(b in store._done for b in blockers):
            out.append(t)
    return out
''',
    '''
g = _mod.load_tasks(["a", "b", "c"], [("a", "b"), ("b", "c")], done=["a"])
assert _mod.has_cycle(g) is False
assert _mod.ready_tasks(g) == ["b"]
cyc = _mod.load_tasks(["x", "y"], [("x", "y"), ("y", "x")])
assert _mod.has_cycle(cyc) is True
''',
    '''"""DonTizi/CodeGeass#2 — task DAG cycle detection and ready frontier."""

node Task {
    has tid: str;
    has done: bool = False;
}

edge DependsOn {}

obj TaskGraph {
    has tasks: dict[str, Task] = {};
}

walker CycleWalk {
    has state: dict[str, int] = {};
    has found: bool = False;

    can step with Task entry {
        st = self.state.get(here.tid, 0);
        if st == 1 {
            self.found = True;
            disengage;
        }
        if st == 2 { skip; }
        self.state[here.tid] = 1;
        visit [->:DependsOn:->][?:Task];
        self.state[here.tid] = 2;
    }
}

def load_tasks(
    tasks: list[str],
    edges: list[tuple[str, str]],
    done: list[str] | None = None,
) -> TaskGraph {
    g = TaskGraph();
    done_set: dict[str, bool] = {};
    if done is not None {
        for d in done { done_set[d] = True; }
    }
    for t in tasks {
        nd = Task(tid=t, done=t in done_set);
        root ++> nd;
        g.tasks[t] = nd;
    }
    for (blocker, blocked) in edges {
        b = g.tasks.get(blocker, None);
        d = g.tasks.get(blocked, None);
        if b is not None and d is not None { d +>:DependsOn:+> b; }
    }
    return g;
}

def has_cycle(store: TaskGraph) -> bool {
    for k in sorted(store.tasks.keys()) {
        nd = store.tasks[k];
        w = nd spawn CycleWalk(state={}, found=False);
        if w.found { return True; }
    }
    return False;
}

def ready_tasks(store: TaskGraph) -> list[str] {
    out: list[str] = [];
    for t in sorted(store.tasks.keys()) {
        nd = store.tasks[t];
        if nd.done { continue; }
        blockers: list[str] = [];
        for d in [nd ->:DependsOn:->][?:Task] { blockers.append(d.tid); }
        ok = True;
        for b in blockers {
            bt = store.tasks.get(b, None);
            if bt is None or not bt.done { ok = False; }
        }
        if ok { out.append(t); }
    }
    return out;
}
''',
    '''
test "dag ready and cycle" {
    g = load_tasks(["a", "b", "c"], [("a", "b"), ("b", "c")], done=["a"]);
    assert has_cycle(g) == False;
    assert ready_tasks(g) == ["b"];
    cyc = load_tasks(["x", "y"], [("x", "y"), ("y", "x")]);
    assert has_cycle(cyc) == True;
}
''',
)

print("issues_24 batch complete")

# --- issues_25 (10) ---

w(
    "iss_DrewBrunning__mycorrhizal-crm__468",
    '''"""DrewBrunning/mycorrhizal-crm#468 — CRM contact relationship reach."""

from collections import deque


class ContactGraph:
    def __init__(self) -> None:
        self._contacts: set[str] = set()
        self._links: dict[str, list[str]] = {}


def load_contacts(names: list[str], edges: list[tuple[str, str]]) -> ContactGraph:
    g = ContactGraph()
    for n in names:
        g._contacts.add(n)
        g._links.setdefault(n, [])
    for a, b in edges:
        if a in g._contacts and b in g._contacts:
            g._links.setdefault(a, []).append(b)
            g._links.setdefault(b, []).append(a)
    return g


def related_contacts(store: ContactGraph, seed: str) -> list[str]:
    if seed not in store._contacts:
        return []
    seen: set[str] = {seed}
    queue: deque[str] = deque([seed])
    while queue:
        cur = queue.popleft()
        for nxt in store._links.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)
''',
    '''
g = _mod.load_contacts(
    ["alice", "bob", "carol", "dave"],
    [("alice", "bob"), ("bob", "carol"), ("alice", "dave")],
)
assert _mod.related_contacts(g, "alice") == ["alice", "bob", "carol", "dave"]
''',
    '''"""DrewBrunning/mycorrhizal-crm#468 — CRM contact relationship reach."""

node Contact {
    has name: str;
}

edge Knows {}

obj ContactGraph {
    has contacts: dict[str, Contact] = {};
}

walker RelWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Contact entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [-->[?:Contact]];
    }
}

def load_contacts(names: list[str], edges: list[tuple[str, str]]) -> ContactGraph {
    g = ContactGraph();
    for n in names {
        nd = Contact(name=n);
        root ++> nd;
        g.contacts[n] = nd;
    }
    for (a, b) in edges {
        ca = g.contacts.get(a, None);
        cb = g.contacts.get(b, None);
        if ca is not None and cb is not None {
            ca +>:Knows:+> cb;
            cb +>:Knows:+> ca;
        }
    }
    return g;
}

def related_contacts(store: ContactGraph, seed: str) -> list[str] {
    nd = store.contacts.get(seed, None);
    if nd is None { return []; }
    w = nd spawn RelWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}
''',
    '''
test "crm relationship reach" {
    g = load_contacts(
        ["alice", "bob", "carol", "dave"],
        [("alice", "bob"), ("bob", "carol"), ("alice", "dave")],
    );
    assert related_contacts(g, "alice") == ["alice", "bob", "carol", "dave"];
}
''',
)

w(
    "iss_Dtronix__Quarry__330",
    '''"""Dtronix/Quarry#330 — employee manager hierarchy descendants."""


def load_employees(managers: dict[str, str | None]) -> dict:
    return {"managers": dict(managers)}


def _descendants(reg: dict, root: str) -> list[str]:
    if root not in reg["managers"]:
        return []
    out: list[str] = []
    stack = [root]
    seen: set[str] = set()
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        out.append(cur)
        for eid, mgr in reg["managers"].items():
            if mgr == cur and eid not in seen:
                stack.append(eid)
    return sorted(out)


def employee_subtree(reg: dict, eid: str) -> list[str]:
    return _descendants(reg, eid)
''',
    '''
reg = _mod.load_employees({"ceo": None, "vp": "ceo", "eng": "vp", "sales": "vp"})
assert _mod.employee_subtree(reg, "ceo") == ["ceo", "eng", "sales", "vp"]
''',
    '''"""Dtronix/Quarry#330 — employee manager hierarchy descendants."""

node Employee {
    has eid: str;
}

edge Manages {}

obj EmployeeTree {
    has staff: dict[str, Employee] = {};
}

walker DescWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Employee entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        self.reached.append(here.eid);
        visit [here ->:Manages:->][?:Employee];
    }
}

def load_employees(managers: dict[str, str | None]) -> EmployeeTree {
    reg = EmployeeTree();
    for eid in managers.keys() {
        nd = Employee(eid=eid);
        root ++> nd;
        reg.staff[eid] = nd;
    }
    for eid in managers.keys() {
        mgr = managers[eid];
        if mgr is not None {
            m = reg.staff.get(mgr, None);
            e = reg.staff.get(eid, None);
            if m is not None and e is not None { m +>:Manages:+> e; }
        }
    }
    return reg;
}

def employee_subtree(reg: EmployeeTree, eid: str) -> list[str] {
    nd = reg.staff.get(eid, None);
    if nd is None { return []; }
    w = nd spawn DescWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}
''',
    '''
test "employee subtree" {
    reg = load_employees({"ceo": None, "vp": "ceo", "eng": "vp", "sales": "vp"});
    assert employee_subtree(reg, "ceo") == ["ceo", "eng", "sales", "vp"];
}
''',
)

w(
    "iss_EXXETA__exxperts__49",
    '''"""EXXETA/exxperts#49 — recursive skill directory scan with visited guard."""

MAX_DEPTH = 16


def load_skill_tree(children: dict[str, list[str]]) -> dict:
    return {"children": {k: list(v) for k, v in children.items()}}


def discover_skills(store: dict, root: str) -> list[str]:
    found: list[str] = []
    seen: set[str] = set()
    stack = [(root, 0)]
    while stack:
        path, depth = stack.pop()
        if path in seen or depth > MAX_DEPTH:
            continue
        seen.add(path)
        if path.endswith("/SKILL.md") or path == root:
            found.append(path)
        for child in store["children"].get(path, []):
            stack.append((child, depth + 1))
    return sorted(found)
''',
    '''
store = _mod.load_skill_tree({
    "/skills": ["/skills/agent-skills", "/skills/direct"],
    "/skills/agent-skills": ["/skills/agent-skills/foo/SKILL.md"],
    "/skills/direct": ["/skills/direct/bar/SKILL.md"],
})
assert _mod.discover_skills(store, "/skills") == [
    "/skills",
    "/skills/agent-skills/foo/SKILL.md",
    "/skills/direct/bar/SKILL.md",
]
''',
    '''"""EXXETA/exxperts#49 — recursive skill directory scan with visited guard."""

glob MAX_DEPTH: int = 16;

node SkillDir {
    has path: str;
}

edge Contains {}

obj SkillTree {
    has nodes: dict[str, SkillDir] = {};
}

walker SkillScan {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has depth: int = 0;

    can step with SkillDir entry {
        if here.path in self.claimed { skip; }
        if self.depth > MAX_DEPTH { disengage; }
        self.claimed[here.path] = True;
        if here.path.endswith("/SKILL.md") or self.depth == 0 {
            self.found.append(here.path);
        }
        visit [->:Contains:->][?:SkillDir] with SkillScan(
            claimed=self.claimed,
            found=self.found,
            depth=self.depth + 1,
        );
    }
}

def load_skill_tree(children: dict[str, list[str]]) -> SkillTree {
    store = SkillTree();
    all_paths: dict[str, bool] = {};
    for p in children.keys() { all_paths[p] = True; }
    for chs in children.values() {
        for c in chs { all_paths[c] = True; }
    }
    for p in all_paths.keys() {
        nd = SkillDir(path=p);
        root ++> nd;
        store.nodes[p] = nd;
    }
    for parent, chs in children.items() {
        pa = store.nodes.get(parent, None);
        if pa is None { continue; }
        for c in chs {
            ch = store.nodes.get(c, None);
            if ch is not None { pa +>:Contains:+> ch; }
        }
    }
    return store;
}

def discover_skills(store: SkillTree, root: str) -> list[str] {
    nd = store.nodes.get(root, None);
    if nd is None { return []; }
    w = nd spawn SkillScan(claimed={}, found=[], depth=0);
    out = w.found;
    out.sort();
    return out;
}
''',
    '''
test "recursive skill discovery" {
    store = load_skill_tree({
        "/skills": ["/skills/agent-skills", "/skills/direct"],
        "/skills/agent-skills": ["/skills/agent-skills/foo/SKILL.md"],
        "/skills/direct": ["/skills/direct/bar/SKILL.md"],
    });
    assert discover_skills(store, "/skills") == [
        "/skills",
        "/skills/agent-skills/foo/SKILL.md",
        "/skills/direct/bar/SKILL.md",
    ];
}
''',
)

w(
    "iss_Emrys02__soroban-band__7",
    '''"""Emrys02/soroban-band#7 — contract dependency cycle detection."""

from collections import deque


class ContractGraph:
    def __init__(self) -> None:
        self._contracts: set[str] = set()
        self._deps: dict[str, list[str]] = {}


def load_contracts(names: list[str], edges: list[tuple[str, str]]) -> ContractGraph:
    g = ContractGraph()
    for n in names:
        g._contracts.add(n)
        g._deps.setdefault(n, [])
    for a, b in edges:
        if a in g._contracts and b in g._contracts:
            g._deps.setdefault(b, []).append(a)
    return g


def find_cycles(store: ContractGraph) -> list[list[str]]:
    cycles: list[list[str]] = []
    state: dict[str, int] = {c: 0 for c in store._contracts}
    path: list[str] = []
    for start in sorted(store._contracts):
        if state[start] != 0:
            continue
        stack: deque[tuple[str, int]] = deque([(start, 0)])
        while stack:
            node, idx = stack[-1]
            if idx == 0:
                if state[node] == 1:
                    if node in path:
                        i = path.index(node)
                        cycles.append(path[i:] + [node])
                    continue
                if state[node] == 2:
                    stack.pop()
                    if path and path[-1] == node:
                        path.pop()
                    continue
                state[node] = 1
                path.append(node)
            deps = store._deps.get(node, [])
            if idx < len(deps):
                stack[-1] = (node, idx + 1)
                stack.append((deps[idx], 0))
            else:
                state[node] = 2
                stack.pop()
                if path and path[-1] == node:
                    path.pop()
    return cycles
''',
    '''
g = _mod.load_contracts(["A", "B", "C"], [("A", "B"), ("B", "C"), ("C", "A")])
cyc = _mod.find_cycles(g)
assert len(cyc) >= 1
assert set(cyc[0]) == {"A", "B", "C"}
''',
    '''"""Emrys02/soroban-band#7 — contract dependency cycle detection."""

node Contract {
    has label: str;
}

edge DependsOn {}

obj ContractGraph {
    has contracts: dict[str, Contract] = {};
}

walker CycleProbe {
    has state: dict[str, int] = {};
    has path: list[str] = [];
    has cycles: list[list[str]] = [];

    can step with Contract entry {
        st = self.state.get(here.label, 0);
        if st == 1 {
            if here.label in self.path {
                i = 0;
                for j in range(len(self.path)) {
                    if self.path[j] == here.label { i = j; break; }
                }
                cyc: list[str] = [];
                for j in range(i, len(self.path)) { cyc.append(self.path[j]); }
                cyc.append(here.label);
                self.cycles.append(cyc);
            }
            skip;
        }
        if st == 2 { skip; }
        self.state[here.label] = 1;
        self.path.append(here.label);
        visit [->:DependsOn:->][?:Contract];
        self.path.pop();
        self.state[here.label] = 2;
    }
}

def load_contracts(names: list[str], edges: list[tuple[str, str]]) -> ContractGraph {
    g = ContractGraph();
    for n in names {
        nd = Contract(label=n);
        root ++> nd;
        g.contracts[n] = nd;
    }
    for (a, b) in edges {
        ca = g.contracts.get(a, None);
        cb = g.contracts.get(b, None);
        if ca is not None and cb is not None { cb +>:DependsOn:+> ca; }
    }
    return g;
}

def find_cycles(store: ContractGraph) -> list[list[str]] {
    all_cycles: list[list[str]] = [];
    for k in sorted(store.contracts.keys()) {
        nd = store.contracts[k];
        w = nd spawn CycleProbe(state={}, path=[], cycles=[]);
        all_cycles = all_cycles + w.cycles;
    }
    return all_cycles;
}
''',
    '''
test "contract cycle ABC" {
    g = load_contracts(["A", "B", "C"], [("A", "B"), ("B", "C"), ("C", "A")]);
    cyc = find_cycles(g);
    assert len(cyc) >= 1;
}
''',
)

w(
    "iss_FraOri03__Lattice__202",
    '''"""FraOri03/Lattice#202 — render cache invalidation downstream sweep."""

from collections import deque


class CacheGraph:
    def __init__(self) -> None:
        self._nodes: set[str] = set()
        self._down: dict[str, list[str]] = {}


def load_cache_graph(nodes: list[str], edges: list[tuple[str, str]]) -> CacheGraph:
    g = CacheGraph()
    for n in nodes:
        g._nodes.add(n)
        g._down.setdefault(n, [])
    for up, down in edges:
        if up in g._nodes and down in g._nodes:
            g._down.setdefault(up, []).append(down)
    return g


def invalidate_downstream(store: CacheGraph, changed: str) -> list[str]:
    if changed not in store._nodes:
        return []
    seen: set[str] = {changed}
    queue: deque[str] = deque([changed])
    out: set[str] = set()
    while queue:
        cur = queue.popleft()
        for nxt in store._down.get(cur, []):
            out.add(nxt)
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(out)
''',
    '''
g = _mod.load_cache_graph(
    ["source", "clip", "effect", "cache_range"],
    [("source", "clip"), ("clip", "effect"), ("effect", "cache_range")],
)
assert _mod.invalidate_downstream(g, "clip") == ["cache_range", "effect"]
''',
    '''"""FraOri03/Lattice#202 — render cache invalidation downstream sweep."""

node CacheNode {
    has name: str;
}

edge Invalidates {}

obj CacheGraph {
    has nodes: dict[str, CacheNode] = {};
}

walker DownWalk {
    has claimed: dict[str, bool] = {};
    has hit: list[str] = [];

    can step with CacheNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.hit.append(here.name);
        visit [->:Invalidates:->][?:CacheNode];
    }
}

def load_cache_graph(nodes: list[str], edges: list[tuple[str, str]]) -> CacheGraph {
    g = CacheGraph();
    for n in nodes {
        nd = CacheNode(name=n);
        root ++> nd;
        g.nodes[n] = nd;
    }
    for (up, down) in edges {
        u = g.nodes.get(up, None);
        d = g.nodes.get(down, None);
        if u is not None and d is not None { u +>:Invalidates:+> d; }
    }
    return g;
}

def invalidate_downstream(store: CacheGraph, changed: str) -> list[str] {
    nd = store.nodes.get(changed, None);
    if nd is None { return []; }
    w = nd spawn DownWalk(claimed={}, hit=[]);
    out: list[str] = [];
    for n in w.hit {
        if n != changed { out.append(n); }
    }
    return sorted(out);
}
''',
    '''
test "cache invalidation downstream" {
    g = load_cache_graph(
        ["source", "clip", "effect", "cache_range"],
        [("source", "clip"), ("clip", "effect"), ("effect", "cache_range")],
    );
    assert invalidate_downstream(g, "clip") == ["cache_range", "effect"];
}
''',
)

w(
    "iss_FrankieJay52__Brinesearch__97",
    '''"""FrankieJay52/Brinesearch#97 — road junction connected-road BFS."""

from collections import deque


class RoadGraph:
    def __init__(self) -> None:
        self._roads: set[str] = set()
        self._junctions: dict[str, list[str]] = {}


def load_roads(roads: list[str], junctions: list[tuple[str, str]]) -> RoadGraph:
    g = RoadGraph()
    for r in roads:
        g._roads.add(r)
        g._junctions.setdefault(r, [])
    for a, b in junctions:
        if a in g._roads and b in g._roads:
            g._junctions.setdefault(a, []).append(b)
            g._junctions.setdefault(b, []).append(a)
    return g


def connected_roads(store: RoadGraph, start: str) -> list[str]:
    if start not in store._roads:
        return []
    seen: set[str] = {start}
    queue: deque[str] = deque([start])
    while queue:
        cur = queue.popleft()
        for nxt in store._junctions.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)
''',
    '''
g = _mod.load_roads(
    ["SR-7", "CR-12", "TR-3", "CR-44"],
    [("SR-7", "CR-12"), ("CR-12", "TR-3"), ("CR-12", "CR-44")],
)
assert _mod.connected_roads(g, "SR-7") == ["CR-12", "CR-44", "SR-7", "TR-3"]
''',
    '''"""FrankieJay52/Brinesearch#97 — road junction connected-road BFS."""

node Road {
    has rid: str;
}

edge Junction {}

obj RoadGraph {
    has roads: dict[str, Road] = {};
}

walker RoadWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Road entry {
        if here.rid in self.claimed { skip; }
        self.claimed[here.rid] = True;
        self.reached.append(here.rid);
        visit [-->[?:Road]];
    }
}

def load_roads(roads: list[str], junctions: list[tuple[str, str]]) -> RoadGraph {
    g = RoadGraph();
    for r in roads {
        nd = Road(rid=r);
        root ++> nd;
        g.roads[r] = nd;
    }
    for (a, b) in junctions {
        ra = g.roads.get(a, None);
        rb = g.roads.get(b, None);
        if ra is not None and rb is not None {
            ra +>:Junction:+> rb;
            rb +>:Junction:+> ra;
        }
    }
    return g;
}

def connected_roads(store: RoadGraph, start: str) -> list[str] {
    nd = store.roads.get(start, None);
    if nd is None { return []; }
    w = nd spawn RoadWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}
''',
    '''
test "road junction reach" {
    g = load_roads(
        ["SR-7", "CR-12", "TR-3", "CR-44"],
        [("SR-7", "CR-12"), ("CR-12", "TR-3"), ("CR-12", "CR-44")],
    );
    assert connected_roads(g, "SR-7") == ["CR-12", "CR-44", "SR-7", "TR-3"];
}
''',
)

w(
    "iss_Growth-Circle__cadis__259",
    '''"""Growth-Circle/cadis#259 — directory index walk with symlink cycle guard."""

MAX_VISITS = 32


def load_dirs(children: dict[str, list[str]]) -> dict:
    return {"children": {k: list(v) for k, v in children.items()}}


def index_paths(store: dict, root: str) -> list[str]:
    found: list[str] = []
    seen: set[str] = set()
    stack = [root]
    while stack:
        cur = stack.pop()
        if cur in seen or len(found) >= MAX_VISITS:
            continue
        seen.add(cur)
        found.append(cur)
        for ch in store["children"].get(cur, []):
            stack.append(ch)
    return sorted(found)
''',
    '''
store = _mod.load_dirs({"/": ["/src", "/loop"], "/src": ["/src/a"], "/loop": ["/"]})
assert _mod.index_paths(store, "/") == ["/", "/loop", "/src", "/src/a"]
''',
    '''"""Growth-Circle/cadis#259 — directory index walk with symlink cycle guard."""

glob MAX_VISITS: int = 32;

node Dir {
    has path: str;
}

edge Contains {}

obj DirIndex {
    has dirs: dict[str, Dir] = {};
}

walker IndexWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Dir entry {
        if here.path in self.claimed { skip; }
        if len(self.found) >= MAX_VISITS { disengage; }
        self.claimed[here.path] = True;
        self.found.append(here.path);
        visit [->:Contains:->][?:Dir];
    }
}

def load_dirs(children: dict[str, list[str]]) -> DirIndex {
    store = DirIndex();
    allp: dict[str, bool] = {};
    for p in children.keys() { allp[p] = True; }
    for chs in children.values() {
        for c in chs { allp[c] = True; }
    }
    for p in allp.keys() {
        nd = Dir(path=p);
        root ++> nd;
        store.dirs[p] = nd;
    }
    for parent, chs in children.items() {
        pa = store.dirs.get(parent, None);
        if pa is None { continue; }
        for c in chs {
            ch = store.dirs.get(c, None);
            if ch is not None { pa +>:Contains:+> ch; }
        }
    }
    return store;
}

def index_paths(store: DirIndex, root: str) -> list[str] {
    nd = store.dirs.get(root, None);
    if nd is None { return []; }
    w = nd spawn IndexWalk(claimed={}, found=[]);
    return sorted(w.found);
}
''',
    '''
test "index symlink cycle guard" {
    store = load_dirs({"/": ["/src", "/loop"], "/src": ["/src/a"], "/loop": ["/"]});
    assert index_paths(store, "/") == ["/", "/loop", "/src", "/src/a"];
}
''',
)

w(
    "iss_Herd-OS__herd__1050",
    '''"""Herd-OS/herd#1050 — review workflow status transition DAG."""

from collections import deque


class StatusGraph:
    def __init__(self) -> None:
        self._statuses: set[str] = set()
        self._next: dict[str, list[str]] = {}


def load_statuses(names: list[str], edges: list[tuple[str, str]]) -> StatusGraph:
    g = StatusGraph()
    for s in names:
        g._statuses.add(s)
        g._next.setdefault(s, [])
    for a, b in edges:
        if a in g._statuses and b in g._statuses:
            g._next.setdefault(a, []).append(b)
    return g


def reachable_statuses(store: StatusGraph, start: str) -> list[str]:
    if start not in store._statuses:
        return []
    seen: set[str] = {start}
    queue: deque[str] = deque([start])
    while queue:
        cur = queue.popleft()
        for nxt in store._next.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)
''',
    '''
g = _mod.load_statuses(
    ["running", "timeout", "timed_out", "failed"],
    [("running", "timeout"), ("timeout", "timed_out"), ("running", "failed")],
)
assert _mod.reachable_statuses(g, "running") == ["failed", "running", "timed_out", "timeout"]
''',
    '''"""Herd-OS/herd#1050 — review workflow status transition DAG."""

node Status {
    has name: str;
}

edge TransitionsTo {}

obj StatusGraph {
    has statuses: dict[str, Status] = {};
}

walker StatusWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Status entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [->:TransitionsTo:->][?:Status];
    }
}

def load_statuses(names: list[str], edges: list[tuple[str, str]]) -> StatusGraph {
    g = StatusGraph();
    for s in names {
        nd = Status(name=s);
        root ++> nd;
        g.statuses[s] = nd;
    }
    for (a, b) in edges {
        sa = g.statuses.get(a, None);
        sb = g.statuses.get(b, None);
        if sa is not None and sb is not None { sa +>:TransitionsTo:+> sb; }
    }
    return g;
}

def reachable_statuses(store: StatusGraph, start: str) -> list[str] {
    nd = store.statuses.get(start, None);
    if nd is None { return []; }
    w = nd spawn StatusWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}
''',
    '''
test "review status reach" {
    g = load_statuses(
        ["running", "timeout", "timed_out", "failed"],
        [("running", "timeout"), ("timeout", "timed_out"), ("running", "failed")],
    );
    assert reachable_statuses(g, "running") == ["failed", "running", "timed_out", "timeout"];
}
''',
)

w(
    "iss_Herd-OS__herd__1019",
    '''"""Herd-OS/herd#1019 — workflow dispatch dependency frontier."""

from collections import deque


class WorkflowGraph:
    def __init__(self) -> None:
        self._steps: set[str] = set()
        self._deps: dict[str, list[str]] = {}
        self._done: set[str] = set()


def load_workflow(steps: list[str], edges: list[tuple[str, str]], done: list[str] | None = None) -> WorkflowGraph:
    g = WorkflowGraph()
    for s in steps:
        g._steps.add(s)
        g._deps.setdefault(s, [])
    for a, b in edges:
        if a in g._steps and b in g._steps:
            g._deps.setdefault(b, []).append(a)
    if done:
        g._done = set(done)
    return g


def dispatch_frontier(store: WorkflowGraph) -> list[str]:
    out: list[str] = []
    for s in sorted(store._steps):
        if s in store._done:
            continue
        if all(d in store._done for d in store._deps.get(s, [])):
            out.append(s)
    return out
''',
    '''
g = _mod.load_workflow(
    ["label", "dispatch", "worker", "report"],
    [("label", "dispatch"), ("dispatch", "worker"), ("worker", "report")],
    done=["label", "dispatch"],
)
assert _mod.dispatch_frontier(g) == ["worker"]
''',
    '''"""Herd-OS/herd#1019 — workflow dispatch dependency frontier."""

node Step {
    has sid: str;
    has done: bool = False;
}

edge Requires {}

obj WorkflowGraph {
    has steps: dict[str, Step] = {};
}

def load_workflow(
    steps: list[str],
    edges: list[tuple[str, str]],
    done: list[str] | None = None,
) -> WorkflowGraph {
    g = WorkflowGraph();
    ds: dict[str, bool] = {};
    if done is not None {
        for d in done { ds[d] = True; }
    }
    for s in steps {
        nd = Step(sid=s, done=s in ds);
        root ++> nd;
        g.steps[s] = nd;
    }
    for (a, b) in edges {
        pa = g.steps.get(a, None);
        pb = g.steps.get(b, None);
        if pa is not None and pb is not None { pb +>:Requires:+> pa; }
    }
    return g;
}

def dispatch_frontier(store: WorkflowGraph) -> list[str] {
    out: list[str] = [];
    for s in sorted(store.steps.keys()) {
        nd = store.steps[s];
        if nd.done { continue; }
        deps: list[str] = [];
        for d in [nd ->:Requires:->][?:Step] { deps.append(d.sid); }
        ok = True;
        for dep in deps {
            dn = store.steps.get(dep, None);
            if dn is None or not dn.done { ok = False; }
        }
        if ok { out.append(s); }
    }
    return out;
}
''',
    '''
test "dispatch frontier" {
    g = load_workflow(
        ["label", "dispatch", "worker", "report"],
        [("label", "dispatch"), ("dispatch", "worker"), ("worker", "report")],
        done=["label", "dispatch"],
    );
    assert dispatch_frontier(g) == ["worker"];
}
''',
)

w(
    "iss_Jacob-Lasky__minecraft-recipe-graph__337",
    '''"""Jacob-Lasky/minecraft-recipe-graph#337 — widget parent hover subtree."""

from collections import deque


class WidgetTree:
    def __init__(self) -> None:
        self._widgets: set[str] = set()
        self._children: dict[str, list[str]] = {}


def load_widgets(names: list[str], edges: list[tuple[str, str]]) -> WidgetTree:
    g = WidgetTree()
    for w in names:
        g._widgets.add(w)
        g._children.setdefault(w, [])
    for parent, child in edges:
        if parent in g._widgets and child in g._widgets:
            g._children.setdefault(parent, []).append(child)
    return g


def hover_subtree(store: WidgetTree, widget: str) -> list[str]:
    if widget not in store._widgets:
        return []
    seen: set[str] = set()
    queue: deque[str] = deque([widget])
    out: list[str] = []
    while queue:
        cur = queue.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        out.append(cur)
        for ch in store._children.get(cur, []):
            queue.append(ch)
    return out
''',
    '''
g = _mod.load_widgets(
    ["root", "panel", "btn", "tip"],
    [("root", "panel"), ("panel", "btn"), ("panel", "tip")],
)
assert _mod.hover_subtree(g, "panel") == ["panel", "btn", "tip"]
''',
    '''"""Jacob-Lasky/minecraft-recipe-graph#337 — widget parent hover subtree."""

node Widget {
    has name: str;
}

edge ChildOf {}

obj WidgetTree {
    has widgets: dict[str, Widget] = {};
}

walker HoverWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Widget entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.order.append(here.name);
        visit [here <-:ChildOf:<-][?:Widget];
    }
}

def load_widgets(names: list[str], edges: list[tuple[str, str]]) -> WidgetTree {
    g = WidgetTree();
    for w in names {
        nd = Widget(name=w);
        root ++> nd;
        g.widgets[w] = nd;
    }
    for (parent, child) in edges {
        pa = g.widgets.get(parent, None);
        ch = g.widgets.get(child, None);
        if pa is not None and ch is not None { ch +>:ChildOf:+> pa; }
    }
    return g;
}

def hover_subtree(store: WidgetTree, widget: str) -> list[str] {
    nd = store.widgets.get(widget, None);
    if nd is None { return []; }
    w = nd spawn HoverWalk(claimed={}, order=[]);
    return w.order;
}
''',
    '''
test "hover subtree order" {
    g = load_widgets(
        ["root", "panel", "btn", "tip"],
        [("root", "panel"), ("panel", "btn"), ("panel", "tip")],
    );
    assert hover_subtree(g, "panel") == ["panel", "btn", "tip"];
}
''',
)

print("issues_25 batch complete")
