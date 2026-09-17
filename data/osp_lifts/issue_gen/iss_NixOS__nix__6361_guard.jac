# Lift of NixOS/nix#6361: infinite recursion detection with a traceable
# dependency-cycle resolver (stack-trace analog for recursive eval).

node Pkg {
    has name: str;
}

edge Depends {}

# Detect and trace a dependency cycle starting from `start` using a
# claim-map + explicit stack; returns the cycle path (trace) or [] if none.
def resolve_dep_trace(deps: dict[str, list[str]], start: str) -> list[str] {
    trace: list[str] = [];
    claim: dict[str, bool] = {};
    stack: list[tuple[str, list[str]]] = [(start, [])];
    while len(stack) {
        cur, path = stack.pop();
        if cur in claim {
            continue;
        }
        claim[cur] = True;
        nxt_path: list[str] = [];
        for p in path { nxt_path.append(p); }
        nxt_path.append(cur);
        if cur in deps and cur in nxt_path[0:len(nxt_path) - 1] and len(nxt_path) > 1 {
            return nxt_path;
        }
        for child in sorted(deps.get(cur, [])) {
            if child == start {
                cyc: list[str] = [];
                for p in nxt_path { cyc.append(p); }
                cyc.append(start);
                return cyc;
            }
            if child not in claim {
                stack.append((child, nxt_path));
            }
        }
    }
    return trace;
}

# Tolerant lookup: unknown ids resolve to [] instead of raising.
def trace_or_empty(deps: dict[str, list[str]], start: str) -> list[str] {
    if start not in deps {
        return [];
    }
    return resolve_dep_trace(deps, start);
}

walker CheckRecursion {
    has claim: dict[str, bool] = {};
    has cycle_at: str = "";
    has found: bool = False;

    can inspect with Pkg entry {
        if here.name in self.claim {
            self.found = True;
            self.cycle_at = here.name;
            print("infinite recursion detected at:", here.name);
            skip;
        }
        self.claim[here.name] = True;
        print("visiting", here.name);
        kids: list[Pkg] = [here ->:Depends:->Pkg];
        visit kids else { disengage; }
    }
}

test "cycle trace closes the loop" {
    deps: dict[str, list[str]] = {"poetry2nix": ["mrchef"], "mrchef": ["functor"], "functor": ["poetry2nix"]};
    tr = resolve_dep_trace(deps, "poetry2nix");
    assert len(tr) == 4;
    assert tr[0] == tr[len(tr) - 1];
    assert sorted(tr[0:3]) == ["functor", "mrchef", "poetry2nix"];
}

test "acyclic graph yields empty trace" {
    deps: dict[str, list[str]] = {"a": ["b"], "b": ["c"], "c": []};
    assert resolve_dep_trace(deps, "a") == [];
}

test "unknown id tolerated" {
    deps: dict[str, list[str]] = {"a": ["b"]};
    assert trace_or_empty(deps, "zzz") == [];
    assert trace_or_empty(deps, "a") == [];
}

test "diamond revisit via walker claim map" {
    a = Pkg(name="a");
    b = Pkg(name="b");
    c = Pkg(name="c");
    d = Pkg(name="d");
    root ++> a;
    a +>:Depends:+> b;
    a +>:Depends:+> c;
    b +>:Depends:+> d;
    c +>:Depends:+> d;
    d +>:Depends:+> a;
    w = a spawn CheckRecursion(claim={}, cycle_at="", found=False);
    assert w.found;
    assert w.cycle_at == "a";
}

test "self recursion traced immediately" {
    deps: dict[str, list[str]] = {"solo": ["solo"]};
    tr = resolve_dep_trace(deps, "solo");
    assert tr == ["solo", "solo"];
}
