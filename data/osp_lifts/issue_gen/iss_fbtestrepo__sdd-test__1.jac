// fbtestrepo/sdd-test#1 — Component Dependency Graph API (OSP lift).

obj ComponentGraph {
    has stamp: int = 0;
}

node Component {
    has name: str;
    has pkg: str;
}

edge DependsOn {}
edge ChildOf {}

walker FindComponent {
    has target: str;
    has reports: list[Component] = [];

    can search with Root entry {
        visit [-->][?:Component];
    }

    can pick with Component entry {
        if here.name == self.target {
            report here;
            disengage;
        }
        visit [-->];
    }
}

walker TransitiveDeps {
    has claimed: dict[str, bool] = {};
    has acc: list[str] = [];

    can start with Component entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.acc.append(here.name);
        visit [->:DependsOn:->][?:Component];
    }

    can step with Component entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.acc.append(here.name);
        visit [->:DependsOn:->][?:Component] else { disengage; };
    }
}

walker CycleProbe {
    has claimed: dict[str, bool] = {};
    has active: dict[str, bool] = {};
    has found: bool = False;

    can begin with Root entry { visit [-->][?:Component]; }

    can probe with Component entry {
        if self.found { skip; }
        if here.name in self.active and self.active[here.name] {
            self.found = True;
            skip;
        }
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.active[here.name] = True;
        visit [->:DependsOn:->][?:Component] else {
            self.active[here.name] = False;
            disengage;
        };
    }

    can unwind with Component exit { self.active[here.name] = False; }
}

walker PathWalker {
    has src: str;
    has dst: str;
    has parent_map: dict[str, str] = {};
    has claimed: dict[str, bool] = {};
    has found: bool = False;
    has reports: list[list[str]] = [];

    can launch with Root entry { visit [-->][?:Component]; }

    can seed with Component entry {
        if here.name != self.src { visit [-->]; return; }
        self.claimed[self.src] = True;
        if self.src == self.dst {
            report [self.src];
            disengage;
        }
        visit [->:DependsOn:->][?:Component];
    }

    can expand with Component entry {
        if self.found { skip; }
        if here.name in self.claimed { skip; }
        for p in [here<--][?:Component] {
            if p.name in self.claimed {
                self.parent_map[here.name] = p.name;
                break;
            }
        }
        if here.name not in self.parent_map and here.name != self.src { skip; }
        self.claimed[here.name] = True;
        if here.name == self.dst {
            path: list[str] = [];
            cur: str | None = self.dst;
            while cur is not None {
                path.append(cur);
                if cur == self.src { break; }
                cur = self.parent_map.get(cur, None);
            }
            path.reverse();
            report path;
            disengage;
        }
        visit [->:DependsOn:->][?:Component] else { disengage; };
    }
}

def _find_component(target: str) -> Component | None {
    result = root spawn FindComponent(target=target);
    if result.reports { return result.reports[0]; }
    return None;
}

def build_graph(
    specs: list[tuple[str, str, str | None, list[str]]],
) -> ComponentGraph {
    id_map: dict[str, Component] = {};
    for (name, pkg, _parent, _deps) in specs {
        if name not in id_map {
            comp = Component(name=name, pkg=pkg);
            root ++> comp;
            id_map[name] = comp;
        }
    }
    for (name, _pkg, parent, deps) in specs {
        comp = id_map[name];
        for dep_name in deps {
            dep = id_map.get(dep_name, None);
            if dep is not None { comp +>:DependsOn:+> dep; }
        }
        if parent is not None {
            par = id_map.get(parent, None);
            if par is not None { par +>:ChildOf:+> comp; }
        }
    }
    return ComponentGraph(stamp=1);
}

def direct_deps(g: ComponentGraph, name: str) -> list[str] {
    _ = g;
    comp = _find_component(name);
    if comp is None { return []; }
    return sorted([d.name for d in [comp ->:DependsOn:->][?:Component]]);
}

def transitive_deps(g: ComponentGraph, name: str) -> list[str] {
    _ = g;
    comp = _find_component(name);
    if comp is None { return []; }
    w = comp spawn TransitiveDeps();
    filtered = [n for n in w.acc if n != name];
    return sorted(filtered);
}

def children(g: ComponentGraph, name: str) -> list[str] {
    _ = g;
    comp = _find_component(name);
    if comp is None { return []; }
    return sorted([c.name for c in [comp ->:ChildOf:->][?:Component]]);
}

def ancestors(g: ComponentGraph, name: str) -> list[str] {
    _ = g;
    comp = _find_component(name);
    if comp is None { return []; }
    acc: list[str] = [];
    cur = comp;
    seen: dict[str, bool] = {};
    while True {
        parents = [cur <-:ChildOf:<-][?:Component];
        if not parents { break; }
        par = parents[0];
        if par.name in seen { break; }
        seen[par.name] = True;
        acc.append(par.name);
        cur = par;
    }
    return acc;
}

def has_cycle(g: ComponentGraph) -> bool {
    _ = g;
    w = root spawn CycleProbe();
    return w.found;
}

def path_to(g: ComponentGraph, src: str, dst: str) -> list[str] | None {
    _ = g;
    if _find_component(src) is None or _find_component(dst) is None { return None; }
    result = root spawn PathWalker(src=src, dst=dst);
    if result.reports and len(result.reports) > 0 {
        path = result.reports[0];
        if len(path) == 0 { return None; }
        return path;
    }
    return None;
}

def build_order(g: ComponentGraph) -> list[str] | None {
    _ = g;
    if has_cycle(g) { return None; }
    pending: dict[str, bool] = {};
    for c in [-->][?:Component] { pending[c.name] = True; }
    order: list[str] = [];
    progress = True;
    while progress {
        progress = False;
        for nm in sorted(pending.keys()) {
            comp = _find_component(nm);
            if comp is None { continue; }
            ready = True;
            for d in [comp ->:DependsOn:->][?:Component] {
                if d.name in pending { ready = False; break; }
            }
            if ready {
                del pending[nm];
                order.append(nm);
                progress = True;
            }
        }
    }
    return order if not pending else None;
}
