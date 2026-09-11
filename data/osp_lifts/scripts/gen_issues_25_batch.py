#!/usr/bin/env python3
"""Generate issues_25 batch (10 records) in issue_gen/."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ISSUE_GEN = ROOT / "issue_gen"


def write(stem: str, py: str, ref_body: str, jac: str, tests: str) -> None:
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
    ISSUE_GEN.mkdir(exist_ok=True)
    (ISSUE_GEN / f"{stem}.py").write_text(py)
    (ISSUE_GEN / f"{stem}.ref.py").write_text(ref)
    (ISSUE_GEN / f"{stem}.jac").write_text(jac)
    (ISSUE_GEN / f"{stem}_guard.jac").write_text(jac.rstrip() + "\n\n" + tests.strip() + "\n")


RECORDS: list[tuple[str, str, str, str, str]] = []

# 1. DrewBrunning/mycorrhizal-crm#468 — CRM relationship reach (C2)
RECORDS.append((
    "iss_DrewBrunning__mycorrhizal-crm__468",
    '''"""DrewBrunning/mycorrhizal-crm#468 — multi-hop CRM relationship reach."""

from __future__ import annotations

from collections import deque


class CrmGraph:
    def __init__(self) -> None:
        self._contacts: set[str] = set()
        self._related: dict[str, list[str]] = {}


def load_crm(
    contacts: list[str],
    relation_edges: list[tuple[str, str]],
) -> CrmGraph:
    g = CrmGraph()
    for cid in contacts:
        g._contacts.add(cid)
        g._related.setdefault(cid, [])
    for a, b in relation_edges:
        if a in g._contacts and b in g._contacts:
            g._related.setdefault(a, []).append(b)
            g._related.setdefault(b, g._related.get(b, []))
    return g


def reachable_contacts(store: CrmGraph, start: str) -> list[str]:
    if start not in store._contacts:
        return []
    seen: set[str] = set()
    queue: deque[str] = deque([start])
    while queue:
        cur = queue.popleft()
        for nxt in store._related.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)


def relationship_hops(store: CrmGraph, start: str) -> int:
    if start not in store._contacts:
        return -1
    depth: dict[str, int] = {start: 0}
    queue: deque[str] = deque([start])
    best = 0
    while queue:
        cur = queue.popleft()
        for nxt in store._related.get(cur, []):
            nd = depth[cur] + 1
            if nd > best:
                best = nd
            if nxt not in depth or nd > depth[nxt]:
                depth[nxt] = nd
                queue.append(nxt)
    return best


def hub_neighbors(store: CrmGraph, hub_id: str) -> list[str]:
    if hub_id not in store._contacts:
        return []
    return sorted(store._related.get(hub_id, []))
''',
    '''
g = _mod.load_crm(
    ["alice", "bob", "carol", "dave", "eve"],
    [("alice", "bob"), ("bob", "carol"), ("alice", "dave"), ("dave", "eve")],
)
assert _mod.reachable_contacts(g, "alice") == ["bob", "carol", "dave", "eve"]
assert _mod.relationship_hops(g, "alice") == 2
assert _mod.hub_neighbors(g, "alice") == ["bob", "dave"]
assert _mod.reachable_contacts(g, "ghost") == []

diamond = _mod.load_crm(
    ["hub", "a", "b", "tip"],
    [("hub", "a"), ("hub", "b"), ("a", "tip"), ("b", "tip")],
)
assert _mod.reachable_contacts(diamond, "hub") == ["a", "b", "tip"]
''',
    '''"""DrewBrunning/mycorrhizal-crm#468 — multi-hop CRM relationship reach."""

node Contact {
    has cid: str;
}

edge RelatedTo {}

obj CrmGraph {
    has contacts: dict[str, Contact] = {};
}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has anchor: str = "";

    can step with Contact entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid != self.anchor { self.reached.append(here.cid); }
        visit [->:RelatedTo:->][?:Contact];
    }
}

def load_crm(
    contacts: list[str],
    relation_edges: list[tuple[str, str]],
) -> CrmGraph {
    g = CrmGraph();
    for cid in contacts {
        nd = Contact(cid=cid);
        root ++> nd;
        g.contacts[cid] = nd;
    }
    for (a, b) in relation_edges {
        na = g.contacts.get(a, None);
        nb = g.contacts.get(b, None);
        if na is not None and nb is not None { na +>:RelatedTo:+> nb; }
    }
    return g;
}

def reachable_contacts(store: CrmGraph, start: str) -> list[str] {
    nd = store.contacts.get(start, None);
    if nd is None { return []; }
    w = nd spawn ReachWalk(claimed={}, anchor=start);
    return sorted(w.reached);
}

def relationship_hops(store: CrmGraph, start: str) -> int {
    nd = store.contacts.get(start, None);
    if nd is None { return -1; }
    depth: dict[str, int] = {start: 0};
    frontier: list[Contact] = [nd];
    best = 0;
    while len(frontier) > 0 {
        cur = frontier.pop(0);
        for nxt in [cur ->:RelatedTo:->][?:Contact] {
            nd2 = depth[cur.cid] + 1;
            if nd2 > best { best = nd2; }
            if not (nxt.cid in depth) or nd2 > depth[nxt.cid] {
                depth[nxt.cid] = nd2;
                frontier.append(nxt);
            }
        }
    }
    return best;
}

def hub_neighbors(store: CrmGraph, hub_id: str) -> list[str] {
    nd = store.contacts.get(hub_id, None);
    if nd is None { return []; }
    out: list[str] = [];
    for n in [nd ->:RelatedTo:->][?:Contact] { out.append(n.cid); }
    return sorted(out);
}
''',
    '''
test "crm reach linear" {
    g = load_crm(
        ["alice", "bob", "carol", "dave", "eve"],
        [("alice", "bob"), ("bob", "carol"), ("alice", "dave"), ("dave", "eve")],
    );
    assert reachable_contacts(g, "alice") == ["bob", "carol", "dave", "eve"];
    assert relationship_hops(g, "alice") == 2;
}

test "diamond adversarial revisit" {
    g = load_crm(
        ["hub", "a", "b", "tip"],
        [("hub", "a"), ("hub", "b"), ("a", "tip"), ("b", "tip")],
    );
    assert reachable_contacts(g, "hub") == ["a", "b", "tip"];
}
''',
))

# 2. Dtronix/Quarry#330 — employee manager tree descendants (C1)
RECORDS.append((
    "iss_Dtronix__Quarry__330",
    '''"""Dtronix/Quarry#330 — employee manager tree descendant enumeration."""

from __future__ import annotations

from collections import deque


class OrgStore:
    def __init__(self) -> None:
        self._employees: set[str] = set()
        self._manager: dict[str, str | None] = {}
        self._reports: dict[str, list[str]] = {}


def load_org(
    employees: list[str],
    manager_edges: list[tuple[str, str]],
) -> OrgStore:
    store = OrgStore()
    for eid in employees:
        store._employees.add(eid)
        store._manager[eid] = None
        store._reports.setdefault(eid, [])
    for mgr, rep in manager_edges:
        if mgr in store._employees and rep in store._employees:
            store._manager[rep] = mgr
            store._reports.setdefault(mgr, []).append(rep)
    return store


def manager_descendants(store: OrgStore, emp_id: str) -> list[str]:
    if emp_id not in store._employees:
        return []
    seen: set[str] = set()
    queue: deque[str] = deque(store._reports.get(emp_id, []))
    while queue:
        cur = queue.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for rep in store._reports.get(cur, []):
            if rep not in seen:
                queue.append(rep)
    return sorted(seen)


def reporting_depth(store: OrgStore, emp_id: str) -> int:
    if emp_id not in store._employees:
        return -1
    depth = 0
    cur: str | None = emp_id
    seen: set[str] = set()
    while cur is not None:
        if cur in seen:
            return -1
        seen.add(cur)
        mgr = store._manager.get(cur)
        if mgr is None:
            break
        depth += 1
        cur = mgr
    return depth


def direct_reports(store: OrgStore, emp_id: str) -> list[str]:
    if emp_id not in store._employees:
        return []
    return sorted(store._reports.get(emp_id, []))
''',
    '''
org = _mod.load_org(
    ["ceo", "vp", "eng1", "eng2", "intern"],
    [("ceo", "vp"), ("vp", "eng1"), ("vp", "eng2"), ("eng1", "intern")],
)
assert _mod.manager_descendants(org, "ceo") == ["eng1", "eng2", "intern", "vp"]
assert _mod.direct_reports(org, "vp") == ["eng1", "eng2"]
assert _mod.reporting_depth(org, "intern") == 3
assert _mod.manager_descendants(org, "missing") == []
''',
    '''"""Dtronix/Quarry#330 — employee manager tree descendant enumeration."""

node Employee {
    has eid: str;
}

edge ReportsTo {}

obj OrgStore {
    has employees: dict[str, Employee] = {};
}

walker DescendantWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Employee entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        self.found.append(here.eid);
        visit [->:ReportsTo:->][?:Employee];
    }
}

def load_org(
    employees: list[str],
    manager_edges: list[tuple[str, str]],
) -> OrgStore {
    store = OrgStore();
    for eid in employees {
        nd = Employee(eid=eid);
        root ++> nd;
        store.employees[eid] = nd;
    }
    for (mgr, rep) in manager_edges {
        m = store.employees.get(mgr, None);
        r = store.employees.get(rep, None);
        if m is not None and r is not None { m +>:ReportsTo:+> r; }
    }
    return store;
}

def manager_descendants(store: OrgStore, emp_id: str) -> list[str] {
    nd = store.employees.get(emp_id, None);
    if nd is None { return []; }
    w = nd spawn DescendantWalk(claimed={emp_id: True});
    return sorted(w.found);
}

def reporting_depth(store: OrgStore, emp_id: str) -> int {
    nd = store.employees.get(emp_id, None);
    if nd is None { return -1; }
    depth = 0;
    cur: Employee | None = nd;
    claimed: dict[str, bool] = {};
    while cur is not None {
        if cur.eid in claimed { return -1; }
        claimed[cur.eid] = True;
        mgrs = [cur <-:ReportsTo:<-][?:Employee];
        if len(mgrs) == 0 { break; }
        depth += 1;
        cur = mgrs[0];
    }
    return depth;
}

def direct_reports(store: OrgStore, emp_id: str) -> list[str] {
    nd = store.employees.get(emp_id, None);
    if nd is None { return []; }
    out: list[str] = [];
    for r in [nd ->:ReportsTo:->][?:Employee] { out.append(r.eid); }
    return sorted(out);
}
''',
    '''
test "manager tree descendants" {
    org = load_org(
        ["ceo", "vp", "eng1", "eng2", "intern"],
        [("ceo", "vp"), ("vp", "eng1"), ("vp", "eng2"), ("eng1", "intern")],
    );
    assert manager_descendants(org, "ceo") == ["eng1", "eng2", "intern", "vp"];
    assert direct_reports(org, "vp") == ["eng1", "eng2"];
    assert reporting_depth(org, "intern") == 3;
}

test "diamond reports revisit" {
    org = load_org(
        ["boss", "l", "r", "leaf"],
        [("boss", "l"), ("boss", "r"), ("l", "leaf"), ("r", "leaf")],
    );
    assert manager_descendants(org, "boss") == ["l", "leaf", "r"];
}
''',
))

# 3. EXXETA/exxperts#49 — skill dir recursive scan (C2)
RECORDS.append((
    "iss_EXXETA__exxperts__49",
    '''"""EXXETA/exxperts#49 — recursive skill directory scan with symlink cycle guard."""

from __future__ import annotations

from collections import deque

MAX_SCAN = 256


class SkillIndex:
    def __init__(self) -> None:
        self._dirs: set[str] = set()
        self._children: dict[str, list[str]] = {}
        self._has_skill: dict[str, bool] = {}
        self._symlinks: dict[str, str] = {}


def load_skill_index(
    dirs: list[str],
    child_edges: list[tuple[str, str]],
    symlinks: list[tuple[str, str]] | None = None,
    skill_dirs: list[str] | None = None,
) -> SkillIndex:
    idx = SkillIndex()
    for d in dirs:
        idx._dirs.add(d)
        idx._children.setdefault(d, [])
        idx._has_skill[d] = False
    for parent, child in child_edges:
        if parent in idx._dirs and child in idx._dirs:
            idx._children.setdefault(parent, []).append(child)
    if symlinks:
        for link, target in symlinks:
            if link in idx._dirs and target in idx._dirs:
                idx._symlinks[link] = target
    if skill_dirs:
        for d in skill_dirs:
            if d in idx._dirs:
                idx._has_skill[d] = True
    return idx


def _resolve(idx: SkillIndex, path: str, seen_links: set[str]) -> str:
    while path in idx._symlinks:
        if path in seen_links:
            return path
        seen_links.add(path)
        path = idx._symlinks[path]
    return path


def discover_skills(idx: SkillIndex, root: str) -> list[str]:
    if root not in idx._dirs:
        return []
    found: list[str] = []
    visited: set[str] = set()
    queue: deque[str] = deque([root])
    steps = 0
    while queue and steps < MAX_SCAN:
        steps += 1
        cur = queue.popleft()
        canon = _resolve(idx, cur, set())
        if canon in visited:
            continue
        visited.add(canon)
        if idx._has_skill.get(canon, False):
            found.append(canon)
        for child in idx._children.get(canon, idx._children.get(cur, [])):
            queue.append(child)
        if cur in idx._symlinks:
            queue.append(idx._symlinks[cur])
    return sorted(found)


def scan_visit_count(idx: SkillIndex, root: str) -> int:
    if root not in idx._dirs:
        return 0
    visited: set[str] = set()
    queue: deque[str] = deque([root])
    steps = 0
    while queue and steps < MAX_SCAN:
        steps += 1
        cur = queue.popleft()
        canon = _resolve(idx, cur, set())
        if canon in visited:
            continue
        visited.add(canon)
        for child in idx._children.get(canon, []):
            queue.append(child)
        if cur in idx._symlinks:
            queue.append(idx._symlinks[cur])
    return len(visited)


def has_symlink_cycle(idx: SkillIndex, root: str) -> bool:
    if root not in idx._dirs:
        return False
    visited: set[str] = set()
    queue: deque[str] = deque([root])
    steps = 0
    while queue and steps < MAX_SCAN:
        steps += 1
        cur = queue.popleft()
        link_seen: set[str] = set()
        canon = _resolve(idx, cur, link_seen)
        if len(link_seen) > 0 and canon in link_seen:
            return True
        if canon in visited:
            continue
        visited.add(canon)
        for child in idx._children.get(canon, []):
            queue.append(child)
        if cur in idx._symlinks:
            queue.append(idx._symlinks[cur])
    return False
''',
    '''
idx = _mod.load_skill_index(
    ["root", "pkg", "skills", "s1", "s2"],
    [("root", "pkg"), ("pkg", "skills"), ("skills", "s1"), ("skills", "s2")],
    skill_dirs=["s1", "s2"],
)
assert _mod.discover_skills(idx, "root") == ["s1", "s2"]
assert _mod.scan_visit_count(idx, "root") == 5
loop = _mod.load_skill_index(["a", "b"], [], symlinks=[("a", "b"), ("b", "a")])
assert _mod.has_symlink_cycle(loop, "a") is True
''',
    '''"""EXXETA/exxperts#49 — recursive skill directory scan with symlink cycle guard."""

glob MAX_SCAN: int = 256;

node SkillDir {
    has path: str;
    has has_skill: bool = False;
}

edge ChildDir {}

edge SymlinkTo {}

obj SkillIndex {
    has dirs: dict[str, SkillDir] = {};
}

walker SkillScan {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has steps: int = 0;
    has cycle_hit: bool = False;

    can step with SkillDir entry {
        if self.steps >= MAX_SCAN { disengage; }
        self.steps += 1;
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        if here.has_skill { self.found.append(here.path); }
        visit [->:ChildDir:->][?:SkillDir];
        for tgt in [here ->:SymlinkTo:->][?:SkillDir] {
            if tgt.path in self.claimed { self.cycle_hit = True; skip; }
            visit [tgt];
        }
    }
}

def load_skill_index(
    dirs: list[str],
    child_edges: list[tuple[str, str]],
    symlinks: list[tuple[str, str]] | None = None,
    skill_dirs: list[str] | None = None,
) -> SkillIndex {
    idx = SkillIndex();
    skill_set: dict[str, bool] = {};
    if skill_dirs is not None {
        for d in skill_dirs { skill_set[d] = True; }
    }
    for d in dirs {
        nd = SkillDir(path=d, has_skill=d in skill_set);
        root ++> nd;
        idx.dirs[d] = nd;
    }
    for (parent, child) in child_edges {
        p = idx.dirs.get(parent, None);
        c = idx.dirs.get(child, None);
        if p is not None and c is not None { p +>:ChildDir:+> c; }
    }
    if symlinks is not None {
        for (link, target) in symlinks {
            ln = idx.dirs.get(link, None);
            tg = idx.dirs.get(target, None);
            if ln is not None and tg is not None { ln +>:SymlinkTo:+> tg; }
        }
    }
    return idx;
}

def discover_skills(idx: SkillIndex, `root: str) -> list[str] {
    nd = idx.dirs.get(`root, None);
    if nd is None { return []; }
    w = nd spawn SkillScan();
    return sorted(w.found);
}

def scan_visit_count(idx: SkillIndex, `root: str) -> int {
    nd = idx.dirs.get(`root, None);
    if nd is None { return 0; }
    w = nd spawn SkillScan();
    return len(w.claimed.keys());
}

def has_symlink_cycle(idx: SkillIndex, `root: str) -> bool {
    nd = idx.dirs.get(`root, None);
    if nd is None { return False; }
    w = nd spawn SkillScan();
    return w.cycle_hit;
}
''',
    '''
test "recursive skill discovery" {
    idx = load_skill_index(
        ["root", "pkg", "skills", "s1", "s2"],
        [("root", "pkg"), ("pkg", "skills"), ("skills", "s1"), ("skills", "s2")],
        skill_dirs=["s1", "s2"],
    );
    assert discover_skills(idx, "root") == ["s1", "s2"];
}

test "symlink cycle guard" {
    loop = load_skill_index(["a", "b"], [], symlinks=[("a", "b"), ("b", "a")]);
    assert has_symlink_cycle(loop, "a") == True;
}
''',
))

# 4. Emrys02/soroban-band#7 — contract dependency cycle detection (C2)
RECORDS.append((
    "iss_Emrys02__soroban-band__7",
    '''"""Emrys02/soroban-band#7 — contract dependency cycle detection."""

from __future__ import annotations


class ContractGraph:
    def __init__(self) -> None:
        self._contracts: set[str] = set()
        self._depends: dict[str, list[str]] = {}


def load_contracts(
    names: list[str],
    depends_edges: list[tuple[str, str]],
) -> ContractGraph:
    g = ContractGraph()
    for name in names:
        g._contracts.add(name)
        g._depends.setdefault(name, [])
    for blocker, blocked in depends_edges:
        if blocker in g._contracts and blocked in g._contracts:
            g._depends.setdefault(blocked, []).append(blocker)
            g._depends.setdefault(blocker, g._depends.get(blocker, []))
    return g


def detect_cycles(store: ContractGraph) -> list[tuple[str, str]]:
    errors: list[tuple[str, str]] = []
    visited: set[str] = set()
    stack: set[str] = set()

    def dfs(node: str) -> None:
        visited.add(node)
        stack.add(node)
        for dep in store._depends.get(node, []):
            if dep in stack:
                errors.append((node, dep))
            elif dep not in visited:
                dfs(dep)
        stack.remove(node)

    for name in sorted(store._contracts):
        if name not in visited:
            dfs(name)
    return sorted(errors)


def cycle_members(store: ContractGraph, start: str) -> list[str] | None:
    if start not in store._contracts:
        return None
    visited: set[str] = set()
    stack: list[str] = []

    def dfs(node: str) -> list[str] | None:
        if node in visited:
            idx = stack.index(node) if node in stack else -1
            if idx >= 0:
                return stack[idx:]
            return None
        visited.add(node)
        stack.append(node)
        for dep in store._depends.get(node, []):
            hit = dfs(dep)
            if hit is not None:
                return hit
        stack.pop()
        return None

    return dfs(start)


def build_order(store: ContractGraph) -> list[str]:
    indeg: dict[str, int] = {n: 0 for n in store._contracts}
    for node in store._contracts:
        for dep in store._depends.get(node, []):
            indeg[node] += 1
    ready = sorted(n for n, d in indeg.items() if d == 0)
    order: list[str] = []
    while ready:
        cur = ready.pop(0)
        order.append(cur)
        for other in sorted(store._contracts):
            if cur in store._depends.get(other, []):
                indeg[other] -= 1
                if indeg[other] == 0:
                    ready.append(other)
                    ready = sorted(ready)
    if len(order) != len(store._contracts):
        return []
    return order
''',
    '''
g = _mod.load_contracts(["A", "B", "C", "D"], [("A", "B"), ("B", "C"), ("A", "D")])
assert _mod.detect_cycles(g) == []
assert _mod.build_order(g) == ["A", "B", "C", "D"]
cyc = _mod.load_contracts(["X", "Y"], [("X", "Y"), ("Y", "X")])
assert _mod.detect_cycles(cyc) == [("Y", "X")]
assert _mod.cycle_members(cyc, "X") == ["X", "Y"]
assert _mod.build_order(cyc) == []
''',
    '''"""Emrys02/soroban-band#7 — contract dependency cycle detection."""

node Contract {
    has name: str;
}

edge DependsOn {}

obj ContractGraph {
    has contracts: dict[str, Contract] = {};
}

walker CycleProbe {
    has visited: dict[str, bool] = {};
    has stack: dict[str, bool] = {};
    has errors: list[tuple[str, str]] = [];

    can step with Contract entry {
        if here.name in self.visited { skip; }
        self.visited[here.name] = True;
        self.stack[here.name] = True;
        for dep in [here ->:DependsOn:->][?:Contract] {
            if dep.name in self.stack {
                self.errors.append((here.name, dep.name));
            } else {
                if not (dep.name in self.visited) { visit [dep]; }
            }
        }
        self.stack[here.name] = False;
    }
}

def load_contracts(
    names: list[str],
    depends_edges: list[tuple[str, str]],
) -> ContractGraph {
    g = ContractGraph();
    for name in names {
        nd = Contract(name=name);
        root ++> nd;
        g.contracts[name] = nd;
    }
    for (blocker, blocked) in depends_edges {
        b = g.contracts.get(blocker, None);
        d = g.contracts.get(blocked, None);
        if b is not None and d is not None { d +>:DependsOn:+> b; }
    }
    return g;
}

def detect_cycles(store: ContractGraph) -> list[tuple[str, str]] {
    errors: list[tuple[str, str]] = [];
    visited: dict[str, bool] = {};
    for k in sorted(store.contracts.keys()) {
        if k in visited { continue; }
        nd = store.contracts[k];
        w = nd spawn CycleProbe(visited=visited, stack={}, errors=[]);
        errors = errors + w.errors;
        visited = w.visited;
    }
    return sorted(errors);
}

def cycle_members(store: ContractGraph, start: str) -> list[str] | None {
    nd = store.contracts.get(start, None);
    if nd is None { return None; }
    w = nd spawn CycleProbe(visited={}, stack={}, errors=[]);
    if len(w.errors) == 0 { return None; }
    (a, b) = w.errors[0];
    return [a, b];
}

def build_order(store: ContractGraph) -> list[str] {
    indeg: dict[str, int] = {};
    for n in store.contracts.keys() { indeg[n] = 0; }
    for (name, nd) in store.contracts.items() {
        for dep in [nd ->:DependsOn:->][?:Contract] {
            indeg[name] += 1;
        }
    }
    ready = sorted([n for (n, d) in indeg.items() if d == 0]);
    order: list[str] = [];
    while len(ready) > 0 {
        cur = ready.pop(0);
        order.append(cur);
        cnd = store.contracts.get(cur, None);
        if cnd is None { continue; }
        for other in store.contracts.keys() {
            ond = store.contracts.get(other, None);
            if ond is None { continue; }
            for dep in [ond ->:DependsOn:->][?:Contract] {
                if dep.name == cur {
                    indeg[other] -= 1;
                    if indeg[other] == 0 {
                        ready.append(other);
                        ready = sorted(ready);
                    }
                }
            }
        }
    }
    if len(order) != len(store.contracts) { return []; }
    return order;
}
''',
    '''
test "dag order" {
    g = load_contracts(["A", "B", "C", "D"], [("A", "B"), ("B", "C"), ("A", "D")]);
    assert detect_cycles(g) == [];
    assert build_order(g) == ["A", "B", "C", "D"];
}

test "simple cycle" {
    cyc = load_contracts(["X", "Y"], [("X", "Y"), ("Y", "X")]);
    assert detect_cycles(cyc) == [("Y", "X")];
    assert build_order(cyc) == [];
}
''',
))

# 5. FraOri03/Lattice#202 — cache invalidation downstream sweep (C2/C5)
RECORDS.append((
    "iss_FraOri03__Lattice__202",
    '''"""FraOri03/Lattice#202 — render cache invalidation downstream sweep."""

from __future__ import annotations

from collections import deque


class TimelineStore:
    def __init__(self) -> None:
        self._clips: set[str] = set()
        self._invalidates: dict[str, list[str]] = {}
        self._dirty: dict[str, bool] = {}


def load_timeline(
    clips: list[str],
    invalidates_edges: list[tuple[str, str]],
) -> TimelineStore:
    store = TimelineStore()
    for cid in clips:
        store._clips.add(cid)
        store._invalidates.setdefault(cid, [])
        store._dirty[cid] = False
    for src, dst in invalidates_edges:
        if src in store._clips and dst in store._clips:
            store._invalidates.setdefault(src, []).append(dst)
    return store


def invalidated_clips(store: TimelineStore, changed: list[str]) -> list[str]:
    seen: set[str] = set()
    queue: deque[str] = deque(ch for ch in changed if ch in store._clips)
    while queue:
        cur = queue.popleft()
        for nxt in store._invalidates.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)


def invalidate_cache(store: TimelineStore, clip_id: str) -> list[str]:
    if clip_id not in store._clips:
        return []
    swept = sorted([clip_id] + list(invalidated_clips(store, [clip_id])))
    for cid in swept:
        store._dirty[cid] = True
    return swept


def is_dirty(store: TimelineStore, clip_id: str) -> bool:
    if clip_id not in store._clips:
        return False
    return store._dirty.get(clip_id, False)
''',
    '''
tl = _mod.load_timeline(
    ["src", "fx", "comp", "out"],
    [("src", "fx"), ("fx", "comp"), ("comp", "out")],
)
assert _mod.invalidated_clips(tl, ["src"]) == ["comp", "fx", "out"]
assert _mod.invalidate_cache(tl, "src") == ["comp", "fx", "out", "src"]
assert _mod.is_dirty(tl, "out") is True
assert _mod.is_dirty(tl, "ghost") is False

diamond = _mod.load_timeline(
    ["edit", "a", "b", "mix"],
    [("edit", "a"), ("edit", "b"), ("a", "mix"), ("b", "mix")],
)
assert _mod.invalidated_clips(diamond, ["edit"]) == ["a", "b", "mix"]
''',
    '''"""FraOri03/Lattice#202 — render cache invalidation downstream sweep."""

node Clip {
    has cid: str;
    has dirty: bool = False;
}

edge Invalidates {}

obj TimelineStore {
    has clips: dict[str, Clip] = {};
}

walker InvalidateWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Clip entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        visit [->:Invalidates:->][?:Clip];
    }
}

def load_timeline(
    clips: list[str],
    invalidates_edges: list[tuple[str, str]],
) -> TimelineStore {
    store = TimelineStore();
    for cid in clips {
        nd = Clip(cid=cid);
        root ++> nd;
        store.clips[cid] = nd;
    }
    for (src, dst) in invalidates_edges {
        s = store.clips.get(src, None);
        d = store.clips.get(dst, None);
        if s is not None and d is not None { s +>:Invalidates:+> d; }
    }
    return store;
}

def invalidated_clips(store: TimelineStore, changed: list[str]) -> list[str] {
    acc: dict[str, bool] = {};
    for ch in changed {
        nd = store.clips.get(ch, None);
        if nd is None { continue; }
        w = nd spawn InvalidateWalk(claimed={ch: True});
        for cid in w.found { acc[cid] = True; }
    }
    return sorted(acc.keys());
}

def invalidate_cache(store: TimelineStore, clip_id: str) -> list[str] {
    if clip_id not in store.clips { return []; }
    swept = sorted([clip_id] + invalidated_clips(store, [clip_id]));
    for cid in swept {
        nd = store.clips.get(cid, None);
        if nd is not None { nd.dirty = True; }
    }
    return swept;
}

def is_dirty(store: TimelineStore, clip_id: str) -> bool {
    nd = store.clips.get(clip_id, None);
    if nd is None { return False; }
    return nd.dirty;
}
''',
    '''
test "downstream invalidation chain" {
    tl = load_timeline(
        ["src", "fx", "comp", "out"],
        [("src", "fx"), ("fx", "comp"), ("comp", "out")],
    );
    assert invalidated_clips(tl, ["src"]) == ["comp", "fx", "out"];
    assert invalidate_cache(tl, "src") == ["comp", "fx", "out", "src"];
}

test "diamond invalidation revisit" {
    tl = load_timeline(
        ["edit", "a", "b", "mix"],
        [("edit", "a"), ("edit", "b"), ("a", "mix"), ("b", "mix")],
    );
    assert invalidated_clips(tl, ["edit"]) == ["a", "b", "mix"];
}
''',
))

# 6. FrankieJay52/Brinesearch#97 — road junction connectivity BFS (C2)
RECORDS.append((
    "iss_FrankieJay52__Brinesearch__97",
    '''"""FrankieJay52/Brinesearch#97 — road junction connectivity via BFS."""

from __future__ import annotations

from collections import deque


class RoadGraph:
    def __init__(self) -> None:
        self._roads: set[str] = set()
        self._junctions: set[str] = set()
        self._road_at: dict[str, list[str]] = {}
        self._connects: dict[str, list[str]] = {}


def load_road_graph(
    roads: list[str],
    junctions: list[str],
    road_junction_edges: list[tuple[str, str]],
    junction_link_edges: list[tuple[str, str]] | None = None,
) -> RoadGraph:
    g = RoadGraph()
    for rid in roads:
        g._roads.add(rid)
        g._road_at.setdefault(rid, [])
    for jid in junctions:
        g._junctions.add(jid)
        g._connects.setdefault(jid, [])
    for road, junction in road_junction_edges:
        if road in g._roads and junction in g._junctions:
            g._road_at.setdefault(road, []).append(junction)
            g._connects.setdefault(junction, []).append(road)
    if junction_link_edges:
        for j1, j2 in junction_link_edges:
            if j1 in g._junctions and j2 in g._junctions:
                g._connects.setdefault(j1, []).append(j2)
                g._connects.setdefault(j2, []).append(j1)
    return g


def connected_roads(store: RoadGraph, road_id: str) -> list[str]:
    if road_id not in store._roads:
        return []
    seen_roads: set[str] = {road_id}
    seen_junctions: set[str] = set()
    queue: deque[str] = deque(store._road_at.get(road_id, []))
    while queue:
        cur = queue.popleft()
        if cur in store._junctions:
            if cur in seen_junctions:
                continue
            seen_junctions.add(cur)
            for nxt in store._connects.get(cur, []):
                if nxt in store._roads and nxt not in seen_roads:
                    seen_roads.add(nxt)
                queue.append(nxt)
        elif cur in store._roads:
            for j in store._road_at.get(cur, []):
                if j not in seen_junctions:
                    queue.append(j)
    seen_roads.discard(road_id)
    return sorted(seen_roads)


def junction_reach(store: RoadGraph, junction_id: str) -> list[str]:
    if junction_id not in store._junctions:
        return []
    seen_junctions: set[str] = {junction_id}
    seen_roads: set[str] = set()
    queue: deque[str] = deque(store._connects.get(junction_id, []))
    while queue:
        cur = queue.popleft()
        if cur in store._junctions:
            if cur in seen_junctions:
                continue
            seen_junctions.add(cur)
            queue.extend(store._connects.get(cur, []))
        elif cur in store._roads:
            if cur in seen_roads:
                continue
            seen_roads.add(cur)
            for j in store._road_at.get(cur, []):
                if j not in seen_junctions:
                    queue.append(j)
    out: list[str] = []
    for j in seen_junctions:
        if j != junction_id:
            out.append(j)
    out.extend(sorted(seen_roads))
    return sorted(out)


def road_component_size(store: RoadGraph, road_id: str) -> int:
    if road_id not in store._roads:
        return 0
    return 1 + len(connected_roads(store, road_id))
''',
    '''
g = _mod.load_road_graph(
    ["r1", "r2", "r3", "r4"],
    ["j1", "j2", "j3"],
    [("r1", "j1"), ("r2", "j1"), ("r2", "j2"), ("r3", "j2"), ("r4", "j3")],
    junction_link_edges=[("j2", "j3")],
)
assert _mod.connected_roads(g, "r1") == ["r2", "r3", "r4"]
assert _mod.junction_reach(g, "j1") == ["j2", "j3", "r1", "r2", "r3", "r4"]
assert _mod.road_component_size(g, "r1") == 4
assert _mod.connected_roads(g, "missing") == []
''',
    '''"""FrankieJay52/Brinesearch#97 — road junction connectivity via BFS."""

node Road {
    has rid: str;
}

node Junction {
    has jid: str;
}

edge AtJunction {}

edge JunctionLink {}

obj RoadGraph {
    has roads: dict[str, Road] = {};
    has junctions: dict[str, Junction] = {};
}

walker RoadReach {
    has claimed_roads: dict[str, bool] = {};
    has claimed_junctions: dict[str, bool] = {};
    has found: list[str] = [];
    has anchor: str = "";

    can step with Road entry {
        if here.rid in self.claimed_roads { skip; }
        self.claimed_roads[here.rid] = True;
        if here.rid != self.anchor { self.found.append(here.rid); }
        visit [->:AtJunction:->][?:Junction];
    }

    can step with Junction entry {
        if here.jid in self.claimed_junctions { skip; }
        self.claimed_junctions[here.jid] = True;
        visit [->:AtJunction:<-][?:Road];
        visit [->:JunctionLink:->][?:Junction];
    }
}

def load_road_graph(
    roads: list[str],
    junctions: list[str],
    road_junction_edges: list[tuple[str, str]],
    junction_link_edges: list[tuple[str, str]] | None = None,
) -> RoadGraph {
    g = RoadGraph();
    for rid in roads {
        nd = Road(rid=rid);
        root ++> nd;
        g.roads[rid] = nd;
    }
    for jid in junctions {
        nd = Junction(jid=jid);
        root ++> nd;
        g.junctions[jid] = nd;
    }
    for (road, junction) in road_junction_edges {
        r = g.roads.get(road, None);
        j = g.junctions.get(junction, None);
        if r is not None and j is not None { r +>:AtJunction:+> j; }
    }
    if junction_link_edges is not None {
        for (j1, j2) in junction_link_edges {
            ja = g.junctions.get(j1, None);
            jb = g.junctions.get(j2, None);
            if ja is not None and jb is not None {
                ja +>:JunctionLink:+> jb;
                jb +>:JunctionLink:+> ja;
            }
        }
    }
    return g;
}

def connected_roads(store: RoadGraph, road_id: str) -> list[str] {
    nd = store.roads.get(road_id, None);
    if nd is None { return []; }
    w = nd spawn RoadReach(anchor=road_id);
    return sorted(w.found);
}

def junction_reach(store: RoadGraph, junction_id: str) -> list[str] {
    nd = store.junctions.get(junction_id, None);
    if nd is None { return []; }
    w = nd spawn RoadReach(anchor="");
    out: list[str] = [];
    for jid in w.claimed_junctions.keys() {
        if jid != junction_id { out.append(jid); }
    }
    for rid in w.claimed_roads.keys() { out.append(rid); }
    return sorted(out);
}

def road_component_size(store: RoadGraph, road_id: str) -> int {
    if road_id not in store.roads { return 0; }
    return 1 + len(connected_roads(store, road_id));
}
''',
    '''
test "road junction reach" {
    g = load_road_graph(
        ["r1", "r2", "r3", "r4"],
        ["j1", "j2", "j3"],
        [("r1", "j1"), ("r2", "j1"), ("r2", "j2"), ("r3", "j2"), ("r4", "j3")],
        junction_link_edges=[("j2", "j3")],
    );
    assert connected_roads(g, "r1") == ["r2", "r3", "r4"];
    assert road_component_size(g, "r1") == 4;
}

test "junction diamond revisit" {
    g = load_road_graph(
        ["ra", "rb", "rc"],
        ["jx", "jy", "jz"],
        [("ra", "jx"), ("rb", "jx"), ("rb", "jy"), ("rc", "jy"), ("rc", "jz")],
        junction_link_edges=[("jx", "jy"), ("jy", "jz")],
    );
    assert connected_roads(g, "ra") == ["rb", "rc"];
}
''',
))

# 7. Growth-Circle/cadis#259 — directory index walk symlink cycle guard (C2)
RECORDS.append((
    "iss_Growth-Circle__cadis__259",
    '''"""Growth-Circle/cadis#259 — directory index walk with symlink cycle guard."""

from __future__ import annotations

from collections import deque

MAX_WALK = 128


class DirIndex:
    def __init__(self) -> None:
        self._dirs: set[str] = set()
        self._children: dict[str, list[str]] = {}
        self._symlinks: dict[str, str] = {}


def load_dir_index(
    dirs: list[str],
    child_edges: list[tuple[str, str]],
    symlinks: list[tuple[str, str]] | None = None,
) -> DirIndex:
    idx = DirIndex()
    for d in dirs:
        idx._dirs.add(d)
        idx._children.setdefault(d, [])
    for parent, child in child_edges:
        if parent in idx._dirs and child in idx._dirs:
            idx._children.setdefault(parent, []).append(child)
    if symlinks:
        for link, target in symlinks:
            if link in idx._dirs and target in idx._dirs:
                idx._symlinks[link] = target
    return idx


def indexed_paths(idx: DirIndex, root: str) -> list[str]:
    if root not in idx._dirs:
        return []
    visited: set[str] = set()
    out: list[str] = []
    queue: deque[str] = deque([root])
    steps = 0
    while queue and steps < MAX_WALK:
        steps += 1
        cur = queue.popleft()
        canon = cur
        link_seen: set[str] = set()
        while canon in idx._symlinks:
            if canon in link_seen:
                break
            link_seen.add(canon)
            canon = idx._symlinks[canon]
        if canon in visited:
            continue
        visited.add(canon)
        out.append(canon)
        for child in idx._children.get(canon, []):
            queue.append(child)
        if cur in idx._symlinks:
            queue.append(idx._symlinks[cur])
    return sorted(out)


def walk_terminates(idx: DirIndex, root: str) -> bool:
    if root not in idx._dirs:
        return True
    visited: set[str] = set()
    queue: deque[str] = deque([root])
    steps = 0
    while queue:
        if steps >= MAX_WALK:
            return False
        steps += 1
        cur = queue.popleft()
        canon = cur
        link_seen: set[str] = set()
        while canon in idx._symlinks:
            if canon in link_seen:
                return True
            link_seen.add(canon)
            canon = idx._symlinks[canon]
        if canon in visited:
            continue
        visited.add(canon)
        for child in idx._children.get(canon, []):
            queue.append(child)
        if cur in idx._symlinks:
            queue.append(idx._symlinks[cur])
    return True


def cycle_detected(idx: DirIndex, root: str) -> bool:
    if root not in idx._dirs:
        return False
    visited: set[str] = set()
    queue: deque[str] = deque([root])
    steps = 0
    while queue and steps < MAX_WALK:
        steps += 1
        cur = queue.popleft()
        link_seen: set[str] = set()
        canon = cur
        while canon in idx._symlinks:
            if canon in link_seen:
                return True
            link_seen.add(canon)
            canon = idx._symlinks[canon]
        if canon in visited:
            return True
        visited.add(canon)
        for child in idx._children.get(canon, []):
            queue.append(child)
        if cur in idx._symlinks:
            queue.append(idx._symlinks[cur])
    return False
''',
    '''
idx = _mod.load_dir_index(
    ["ws", "src", "lib", "tests"],
    [("ws", "src"), ("ws", "tests"), ("src", "lib")],
)
assert _mod.indexed_paths(idx, "ws") == ["lib", "src", "tests", "ws"]
assert _mod.walk_terminates(idx, "ws") is True
assert _mod.cycle_detected(idx, "ws") is False
loop = _mod.load_dir_index(["a", "b"], [], symlinks=[("a", "b"), ("b", "a")])
assert _mod.cycle_detected(loop, "a") is True
''',
    '''"""Growth-Circle/cadis#259 — directory index walk with symlink cycle guard."""

glob MAX_WALK: int = 128;

node DirNode {
    has path: str;
}

edge ChildOf {}

edge SymlinkTo {}

obj DirIndex {
    has dirs: dict[str, DirNode] = {};
}

walker IndexWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has steps: int = 0;
    has cycle_hit: bool = False;

    can step with DirNode entry {
        if self.steps >= MAX_WALK { disengage; }
        self.steps += 1;
        if here.path in self.claimed {
            self.cycle_hit = True;
            skip;
        }
        self.claimed[here.path] = True;
        self.order.append(here.path);
        visit [->:ChildOf:->][?:DirNode];
        for tgt in [here ->:SymlinkTo:->][?:DirNode] {
            if tgt.path in self.claimed { self.cycle_hit = True; skip; }
            visit [tgt];
        }
    }
}

def load_dir_index(
    dirs: list[str],
    child_edges: list[tuple[str, str]],
    symlinks: list[tuple[str, str]] | None = None,
) -> DirIndex {
    idx = DirIndex();
    for d in dirs {
        nd = DirNode(path=d);
        root ++> nd;
        idx.dirs[d] = nd;
    }
    for (parent, child) in child_edges {
        p = idx.dirs.get(parent, None);
        c = idx.dirs.get(child, None);
        if p is not None and c is not None { p +>:ChildOf:+> c; }
    }
    if symlinks is not None {
        for (link, target) in symlinks {
            ln = idx.dirs.get(link, None);
            tg = idx.dirs.get(target, None);
            if ln is not None and tg is not None { ln +>:SymlinkTo:+> tg; }
        }
    }
    return idx;
}

def indexed_paths(idx: DirIndex, `root: str) -> list[str] {
    nd = idx.dirs.get(`root, None);
    if nd is None { return []; }
    w = nd spawn IndexWalk();
    return sorted(w.order);
}

def walk_terminates(idx: DirIndex, `root: str) -> bool {
    nd = idx.dirs.get(`root, None);
    if nd is None { return True; }
    w = nd spawn IndexWalk();
    return w.steps < MAX_WALK;
}

def cycle_detected(idx: DirIndex, `root: str) -> bool {
    nd = idx.dirs.get(`root, None);
    if nd is None { return False; }
    w = nd spawn IndexWalk();
    return w.cycle_hit;
}
''',
    '''
test "directory index walk" {
    idx = load_dir_index(
        ["ws", "src", "lib", "tests"],
        [("ws", "src"), ("ws", "tests"), ("src", "lib")],
    );
    assert indexed_paths(idx, "ws") == ["lib", "src", "tests", "ws"];
    assert walk_terminates(idx, "ws") == True;
}

test "symlink cycle guard" {
    loop = load_dir_index(["a", "b"], [], symlinks=[("a", "b"), ("b", "a")]);
    assert cycle_detected(loop, "a") == True;
}
''',
))

# 8. Herd-OS/herd#1050 — review status transition DAG (C2)
RECORDS.append((
    "iss_Herd-OS__herd__1050",
    '''"""Herd-OS/herd#1050 — review workflow status transition reachability."""

from __future__ import annotations

from collections import deque

CANONICAL = {"approved", "changes_requested", "failed", "timed_out", "unparseable"}


class ReviewWorkflow:
    def __init__(self) -> None:
        self._statuses: set[str] = set()
        self._next: dict[str, list[str]] = {}


def load_review_workflow(
    statuses: list[str],
    transition_edges: list[tuple[str, str]],
) -> ReviewWorkflow:
    wf = ReviewWorkflow()
    for st in statuses:
        wf._statuses.add(st)
        wf._next.setdefault(st, [])
    for src, dst in transition_edges:
        if src in wf._statuses and dst in wf._statuses:
            wf._next.setdefault(src, []).append(dst)
    return wf


def reachable_statuses(store: ReviewWorkflow, from_status: str) -> list[str]:
    if from_status not in store._statuses:
        return []
    seen: set[str] = set()
    queue: deque[str] = deque([from_status])
    while queue:
        cur = queue.popleft()
        for nxt in store._next.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)


def can_transition(store: ReviewWorkflow, from_status: str, to_status: str) -> bool:
    if from_status not in store._statuses or to_status not in store._statuses:
        return False
    return to_status in store._next.get(from_status, [])


def normalize_status(store: ReviewWorkflow, raw: str) -> str | None:
    aliases = {"timeout": "timed_out", "timedout": "timed_out"}
    mapped = aliases.get(raw, raw)
    if mapped in store._statuses:
        return mapped
    if mapped in CANONICAL:
        return mapped if mapped in store._statuses else None
    return None
''',
    '''
wf = _mod.load_review_workflow(
    ["pending", "running", "approved", "changes_requested", "failed", "timed_out", "unparseable"],
    [
        ("pending", "running"),
        ("running", "approved"),
        ("running", "changes_requested"),
        ("running", "failed"),
        ("running", "timed_out"),
        ("running", "unparseable"),
    ],
)
assert _mod.reachable_statuses(wf, "running") == [
    "approved", "changes_requested", "failed", "timed_out", "unparseable"
]
assert _mod.can_transition(wf, "running", "timed_out") is True
assert _mod.can_transition(wf, "running", "timeout") is False
assert _mod.normalize_status(wf, "timeout") == "timed_out"
assert _mod.normalize_status(wf, "bogus") is None
''',
    '''"""Herd-OS/herd#1050 — review workflow status transition reachability."""

glob CANONICAL: list[str] = [
    "approved", "changes_requested", "failed", "timed_out", "unparseable"
];

node ReviewStatus {
    has name: str;
}

edge Allows {}

obj ReviewWorkflow {
    has statuses: dict[str, ReviewStatus] = {};
}

walker StatusReach {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has anchor: str = "";

    can step with ReviewStatus entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.anchor { self.reached.append(here.name); }
        visit [->:Allows:->][?:ReviewStatus];
    }
}

def load_review_workflow(
    statuses: list[str],
    transition_edges: list[tuple[str, str]],
) -> ReviewWorkflow {
    wf = ReviewWorkflow();
    for st in statuses {
        nd = ReviewStatus(name=st);
        root ++> nd;
        wf.statuses[st] = nd;
    }
    for (src, dst) in transition_edges {
        s = wf.statuses.get(src, None);
        d = wf.statuses.get(dst, None);
        if s is not None and d is not None { s +>:Allows:+> d; }
    }
    return wf;
}

def reachable_statuses(store: ReviewWorkflow, from_status: str) -> list[str] {
    nd = store.statuses.get(from_status, None);
    if nd is None { return []; }
    w = nd spawn StatusReach(claimed={}, anchor=from_status);
    return sorted(w.reached);
}

def can_transition(store: ReviewWorkflow, from_status: str, to_status: str) -> bool {
    s = store.statuses.get(from_status, None);
    if s is None { return False; }
    if to_status not in store.statuses { return False; }
    for d in [s ->:Allows:->][?:ReviewStatus] {
        if d.name == to_status { return True; }
    }
    return False;
}

def normalize_status(store: ReviewWorkflow, raw: str) -> str | None {
    mapped = raw;
    if raw == "timeout" { mapped = "timed_out"; }
    if raw == "timedout" { mapped = "timed_out"; }
    if mapped in store.statuses { return mapped; }
    for c in CANONICAL {
        if c == mapped { return mapped if mapped in store.statuses else None; }
    }
    return None;
}
''',
    '''
test "review status reach" {
    wf = load_review_workflow(
        ["pending", "running", "approved", "changes_requested", "failed", "timed_out", "unparseable"],
        [
            ("pending", "running"),
            ("running", "approved"),
            ("running", "changes_requested"),
            ("running", "failed"),
            ("running", "timed_out"),
            ("running", "unparseable"),
        ],
    );
    assert reachable_statuses(wf, "running") == [
        "approved", "changes_requested", "failed", "timed_out", "unparseable"
    ];
    assert normalize_status(wf, "timeout") == "timed_out";
}

test "status diamond revisit" {
    wf = load_review_workflow(
        ["start", "a", "b", "done"],
        [("start", "a"), ("start", "b"), ("a", "done"), ("b", "done")],
    );
    assert reachable_statuses(wf, "start") == ["a", "b", "done"];
}
''',
))

# 9. Herd-OS/herd#1019 — workflow dispatch dependency frontier (C2)
RECORDS.append((
    "iss_Herd-OS__herd__1019",
    '''"""Herd-OS/herd#1019 — workflow dispatch dependency frontier."""

from __future__ import annotations


class DispatchGraph:
    def __init__(self) -> None:
        self._jobs: set[str] = set()
        self._depends: dict[str, list[str]] = {}
        self._status: dict[str, str] = {}


def load_dispatch(
    jobs: list[str],
    depends_edges: list[tuple[str, str]],
    status: dict[str, str] | None = None,
) -> DispatchGraph:
    g = DispatchGraph()
    for jid in jobs:
        g._jobs.add(jid)
        g._depends.setdefault(jid, [])
        g._status[jid] = "pending"
    for blocker, blocked in depends_edges:
        if blocker in g._jobs and blocked in g._jobs:
            g._depends.setdefault(blocked, []).append(blocker)
    if status:
        for k, v in status.items():
            if k in g._jobs:
                g._status[k] = v
    return g


def _open_blockers(store: DispatchGraph, job: str) -> list[str]:
    blockers = store._depends.get(job, [])
    return sorted(b for b in blockers if store._status.get(b) != "done")


def frontier_jobs(store: DispatchGraph) -> list[str]:
    out: list[str] = []
    for jid in sorted(store._jobs):
        if store._status.get(jid) != "pending":
            continue
        if not _open_blockers(store, jid):
            out.append(jid)
    return out


def blocked_by(store: DispatchGraph, job: str) -> list[str]:
    if job not in store._jobs:
        return []
    return _open_blockers(store, job)


def dispatch_ready_count(store: DispatchGraph) -> int:
    return len(frontier_jobs(store))
''',
    '''
g = _mod.load_dispatch(
    ["lint", "test", "build", "deploy"],
    [("lint", "test"), ("test", "build"), ("build", "deploy")],
    {"lint": "done"},
)
assert _mod.frontier_jobs(g) == ["test"]
assert _mod.blocked_by(g, "deploy") == ["build"]
assert _mod.dispatch_ready_count(g) == 1

g2 = _mod.load_dispatch(
    ["a", "b", "c", "d"],
    [("a", "c"), ("b", "c"), ("c", "d")],
)
assert _mod.frontier_jobs(g2) == ["a", "b"]
''',
    '''"""Herd-OS/herd#1019 — workflow dispatch dependency frontier."""

node Job {
    has jid: str;
    has status: str = "pending";
}

edge DependsOn {}

obj DispatchGraph {
    has jobs: dict[str, Job] = {};
}

def load_dispatch(
    jobs: list[str],
    depends_edges: list[tuple[str, str]],
    status: dict[str, str] | None = None,
) -> DispatchGraph {
    g = DispatchGraph();
    for jid in jobs {
        nd = Job(jid=jid);
        root ++> nd;
        g.jobs[jid] = nd;
    }
    for (blocker, blocked) in depends_edges {
        b = g.jobs.get(blocker, None);
        d = g.jobs.get(blocked, None);
        if b is not None and d is not None { d +>:DependsOn:+> b; }
    }
    if status is not None {
        for (k, v) in status.items() {
            nd = g.jobs.get(k, None);
            if nd is not None { nd.status = v; }
        }
    }
    return g;
}

def _open_blockers(store: DispatchGraph, job: str) -> list[str] {
    nd = store.jobs.get(job, None);
    if nd is None { return []; }
    out: list[str] = [];
    for dep in [nd ->:DependsOn:->][?:Job] {
        if dep.status != "done" { out.append(dep.jid); }
    }
    return sorted(out);
}

def frontier_jobs(store: DispatchGraph) -> list[str] {
    out: list[str] = [];
    for jid in sorted(store.jobs.keys()) {
        nd = store.jobs.get(jid, None);
        if nd is None or nd.status != "pending" { continue; }
        if len(_open_blockers(store, jid)) == 0 { out.append(jid); }
    }
    return out;
}

def blocked_by(store: DispatchGraph, job: str) -> list[str] {
    if job not in store.jobs { return []; }
    return _open_blockers(store, job);
}

def dispatch_ready_count(store: DispatchGraph) -> int {
    return len(frontier_jobs(store));
}
''',
    '''
test "dispatch frontier chain" {
    g = load_dispatch(
        ["lint", "test", "build", "deploy"],
        [("lint", "test"), ("test", "build"), ("build", "deploy")],
        {"lint": "done"},
    );
    assert frontier_jobs(g) == ["test"];
    assert dispatch_ready_count(g) == 1;
}

test "diamond frontier" {
    g = load_dispatch(
        ["a", "b", "c", "d"],
        [("a", "c"), ("b", "c"), ("c", "d")],
    );
    assert frontier_jobs(g) == ["a", "b"];
}
''',
))

# 10. Jacob-Lasky/minecraft-recipe-graph#337 — widget parent hover tree (C1)
RECORDS.append((
    "iss_Jacob-Lasky__minecraft-recipe-graph__337",
    '''"""Jacob-Lasky/minecraft-recipe-graph#337 — widget parent hover tree walk."""

from __future__ import annotations

MAX_HOVER = 64


class WidgetTree:
    def __init__(self) -> None:
        self._widgets: set[str] = set()
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._hovered: str | None = None


def load_widgets(
    widgets: list[str],
    parent_edges: list[tuple[str, str]],
    hovered_id: str | None = None,
) -> WidgetTree:
    tree = WidgetTree()
    for wid in widgets:
        tree._widgets.add(wid)
        tree._parent[wid] = None
        tree._children.setdefault(wid, [])
    for parent, child in parent_edges:
        if parent in tree._widgets and child in tree._widgets:
            tree._parent[child] = parent
            tree._children.setdefault(parent, []).append(child)
    if hovered_id in tree._widgets:
        tree._hovered = hovered_id
    return tree


def hovered_ancestors(store: WidgetTree) -> list[str]:
    if store._hovered is None:
        return []
    chain: list[str] = []
    seen: set[str] = set()
    cur: str | None = store._hovered
    while cur is not None and cur in store._widgets:
        if cur in seen:
            break
        if len(chain) >= MAX_HOVER:
            break
        seen.add(cur)
        chain.append(cur)
        cur = store._parent.get(cur)
    return chain


def hover_depth(store: WidgetTree) -> int:
    anc = hovered_ancestors(store)
    return max(len(anc) - 1, 0)


def safe_hover_ids(store: WidgetTree) -> list[str]:
    if store._hovered is None:
        return []
    seen: set[str] = set()
    out: list[str] = []
    queue = list(store._children.get(store._hovered, []))
    while queue and len(out) < MAX_HOVER:
        cur = queue.pop(0)
        if cur in seen:
            continue
        seen.add(cur)
        out.append(cur)
        for ch in store._children.get(cur, []):
            if ch not in seen:
                queue.append(ch)
    return sorted(out)
''',
    '''
tree = _mod.load_widgets(
    ["root", "panel", "slot", "icon", "tip"],
    [("root", "panel"), ("panel", "slot"), ("slot", "icon"), ("icon", "tip")],
    hovered_id="tip",
)
assert _mod.hovered_ancestors(tree) == ["tip", "icon", "slot", "panel", "root"]
assert _mod.hover_depth(tree) == 4
assert _mod.safe_hover_ids(tree) == []

panel_tree = _mod.load_widgets(
    ["root", "panel", "a", "b", "leaf"],
    [("root", "panel"), ("panel", "a"), ("panel", "b"), ("a", "leaf"), ("b", "leaf")],
    hovered_id="panel",
)
assert _mod.safe_hover_ids(panel_tree) == ["a", "b", "leaf"]

empty = _mod.load_widgets(["solo"], [], hovered_id=None)
assert _mod.hovered_ancestors(empty) == []
''',
    '''"""Jacob-Lasky/minecraft-recipe-graph#337 — widget parent hover tree walk."""

glob MAX_HOVER: int = 64;

node Widget {
    has wid: str;
}

edge ChildWidget {}

obj WidgetTree {
    has widgets: dict[str, Widget] = {};
    has hovered: str = "";
}

walker AncestorWalk {
    has chain: list[str] = [];
    has claimed: dict[str, bool] = {};

    can step with Widget entry {
        if here.wid in self.claimed { disengage; }
        if len(self.chain) >= MAX_HOVER { disengage; }
        self.claimed[here.wid] = True;
        self.chain.append(here.wid);
        visit [here <-:ChildWidget:<-][?:Widget] else { disengage; }
    }
}

walker DescendantWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Widget entry {
        if here.wid in self.claimed { skip; }
        if len(self.found) >= MAX_HOVER { disengage; }
        self.claimed[here.wid] = True;
        self.found.append(here.wid);
        visit [->:ChildWidget:->][?:Widget];
    }
}

def load_widgets(
    widgets: list[str],
    parent_edges: list[tuple[str, str]],
    hovered_id: str | None = None,
) -> WidgetTree {
    tree = WidgetTree();
    for wid in widgets {
        nd = Widget(wid=wid);
        root ++> nd;
        tree.widgets[wid] = nd;
    }
    for (parent, child) in parent_edges {
        p = tree.widgets.get(parent, None);
        c = tree.widgets.get(child, None);
        if p is not None and c is not None { p +>:ChildWidget:+> c; }
    }
    if hovered_id is not None and hovered_id in tree.widgets {
        tree.hovered = hovered_id;
    }
    return tree;
}

def hovered_ancestors(store: WidgetTree) -> list[str] {
    if store.hovered == "" { return []; }
    nd = store.widgets.get(store.hovered, None);
    if nd is None { return []; }
    w = nd spawn AncestorWalk();
    return w.chain;
}

def hover_depth(store: WidgetTree) -> int {
    anc = hovered_ancestors(store);
    return len(anc) - 1 if len(anc) > 0 else 0;
}

def safe_hover_ids(store: WidgetTree) -> list[str] {
    if store.hovered == "" { return []; }
    nd = store.widgets.get(store.hovered, None);
    if nd is None { return []; }
    w = nd spawn DescendantWalk(claimed={store.hovered: True});
    return sorted(w.found);
}
''',
    '''
test "hover ancestor chain" {
    tree = load_widgets(
        ["root", "panel", "slot", "icon", "tip"],
        [("root", "panel"), ("panel", "slot"), ("slot", "icon"), ("icon", "tip")],
        hovered_id="tip",
    );
    assert hovered_ancestors(tree) == ["tip", "icon", "slot", "panel", "root"];
    assert hover_depth(tree) == 4;
}

test "hover descendants diamond" {
    tree = load_widgets(
        ["root", "panel", "a", "b", "leaf"],
        [("root", "panel"), ("panel", "a"), ("panel", "b"), ("a", "leaf"), ("b", "leaf")],
        hovered_id="panel",
    );
    assert safe_hover_ids(tree) == ["a", "b", "leaf"];
}
''',
))


def main() -> None:
    for stem, py, ref_body, jac, tests in RECORDS:
        write(stem, py, ref_body, jac, tests)
        print(f"wrote {stem}")


if __name__ == "__main__":
    main()
