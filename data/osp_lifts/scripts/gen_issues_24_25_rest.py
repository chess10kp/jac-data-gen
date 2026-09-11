#!/usr/bin/env python3
"""Generate remaining 18 OSP lift records for issues_24/25."""
from pathlib import Path

IG = Path(__file__).resolve().parents[1] / "issue_gen"


def emit(stem: str, py: str, ref: str, jac: str, tests: str) -> None:
    IG.mkdir(exist_ok=True)
    (IG / f"{stem}.py").write_text(py)
    (IG / f"{stem}.ref.py").write_text(ref)
    (IG / f"{stem}.jac").write_text(jac)
    (IG / f"{stem}_guard.jac").write_text(jac.rstrip() + "\n\n" + tests.strip() + "\n")


def rh(stem: str) -> str:
    return f'''"""Reference harness for {stem}."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("{stem}.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
'''


# 3 sentinel-rbac C1
STEM = "iss_Ashutosh-Malve__sentinel-rbac__7"
emit(
    STEM,
    '''"""Ashutosh-Malve/sentinel-rbac#7 — org unit ancestor chain for authz paths."""


def load_org_units(parents: dict[str, str | None]) -> dict:
    return {"parents": dict(parents)}


def _walk(reg: dict, uid: str) -> list[str]:
    chain: list[str] = []
    seen: set[str] = set()
    cur: str | None = uid
    while cur is not None and cur in reg["parents"]:
        if cur in seen:
            return chain
        seen.add(cur)
        chain.append(cur)
        cur = reg["parents"][cur]
    return chain


def ancestor_units(reg: dict, uid: str) -> list[str]:
    if uid not in reg["parents"]:
        return []
    chain = _walk(reg, uid)
    return list(reversed(chain))


def unit_depth(reg: dict, uid: str) -> int:
    chain = _walk(reg, uid)
    return max(len(chain) - 1, 0)
''',
    rh(STEM)
    + '''
reg = _mod.load_org_units({"root": None, "eng": "root", "payroll": "eng", "team": "payroll"})
assert _mod.ancestor_units(reg, "team") == ["root", "eng", "payroll", "team"]
assert _mod.unit_depth(reg, "team") == 3
assert _mod.ancestor_units(reg, "ghost") == []
''',
    '''"""Ashutosh-Malve/sentinel-rbac#7 — org unit ancestor chain for authz paths."""

node OrgUnit {
    has uid: str;
}

edge ParentOf {}

obj OrgRegistry {
    has units: dict[str, OrgUnit] = {};
}

walker AncestorWalk {
    has chain: list[str] = [];
    has claimed: dict[str, bool] = {};

    can step with OrgUnit entry {
        if here.uid in self.claimed { disengage; }
        self.claimed[here.uid] = True;
        self.chain.append(here.uid);
        visit [here <-:ParentOf:<-] else { disengage; }
    }
}

def load_org_units(parents: dict[str, str | None]) -> OrgRegistry {
    reg = OrgRegistry();
    for uid in parents.keys() {
        nd = OrgUnit(uid=uid);
        root ++> nd;
        reg.units[uid] = nd;
    }
    for uid in parents.keys() {
        p = parents[uid];
        if p is not None {
            pa = reg.units.get(p, None);
            ch = reg.units.get(uid, None);
            if pa is not None and ch is not None { pa +>:ParentOf:+> ch; }
        }
    }
    return reg;
}

def ancestor_units(reg: OrgRegistry, uid: str) -> list[str] {
    nd = reg.units.get(uid, None);
    if nd is None { return []; }
    w = nd spawn AncestorWalk();
    rev: list[str] = [];
    for i in range(len(w.chain) - 1, -1, -1) { rev.append(w.chain[i]); }
    return rev;
}

def unit_depth(reg: OrgRegistry, uid: str) -> int {
    nd = reg.units.get(uid, None);
    if nd is None { return 0; }
    w = nd spawn AncestorWalk();
    return len(w.chain) - 1;
}
''',
    '''
test "org ancestor chain" {
    reg = load_org_units({"root": None, "eng": "root", "payroll": "eng", "team": "payroll"});
    assert ancestor_units(reg, "team") == ["root", "eng", "payroll", "team"];
    assert unit_depth(reg, "team") == 3;
}
''',
)

# 4 docker layers C2
STEM = "iss_BeardedSheeep__assesment-socgen__4"
emit(
    STEM,
    '''"""BeardedSheeep/assesment-socgen#4 — Docker layer invalidation dependency graph."""

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
    rh(STEM)
    + '''
g = _mod.load_layers(
    ["base", "deps", "app_copy", "final"],
    [("base", "deps"), ("deps", "app_copy"), ("app_copy", "final")],
)
assert _mod.invalidated_by(g, "deps") == ["app_copy", "final"]
assert _mod.invalidated_by(g, "missing") == []
''',
    '''"""BeardedSheeep/assesment-socgen#4 — Docker layer invalidation dependency graph."""

node Layer {
    has name: str;
}

edge DependsOn {}

obj LayerGraph {
    has layers: dict[str, Layer] = {};
}

walker InvalidateWalk {
    has claimed: dict[str, bool] = {};
    has hit: list[str] = [];

    can step with Layer entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.hit.append(here.name);
        for nd in self.graph.layers.values() {
            deps = [nd ->:DependsOn:->][?:Layer];
            for d in deps {
                if d.name == here.name and not (nd.name in self.claimed) {
                    visit [nd];
                }
            }
        }
    }

    has graph: LayerGraph;
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
    nd = store.layers.get(changed, None);
    if nd is None { return []; }
    w = nd spawn InvalidateWalk(claimed={}, hit=[], graph=store);
    out: list[str] = [];
    for n in w.hit {
        if n != changed { out.append(n); }
    }
    return sorted(out);
}
''',
    '''
test "layer invalidation cascade" {
    g = load_layers(
        ["base", "deps", "app_copy", "final"],
        [("base", "deps"), ("deps", "app_copy"), ("app_copy", "final")],
    );
    assert invalidated_by(g, "deps") == ["app_copy", "final"];
}
''',
)

print("wrote 2 records, continuing...")
