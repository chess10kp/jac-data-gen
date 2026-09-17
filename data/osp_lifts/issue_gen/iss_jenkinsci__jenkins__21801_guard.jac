# Lift of jenkinsci/jenkins#21801 (JENKINS-33239):
# environment variable resolution must NOT expand recursively;
# a variable referencing itself resolves its own occurrence to empty.

node EnvVar {
    has name: str;
    has raw: str;
    has resolved: str = "";
}

edge Dep {}

# collect closure of vars reachable via Dep edges (claim-map + skip for cycles)
walker Collect {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with EnvVar entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        print("visited " + here.name);
        self.order.append(here.name);
        visit [here ->:Dep:->];
    }
}

def make_env(specs: dict[str, str]) -> dict[str, EnvVar] {
    # build one EnvVar node per spec
    g: dict[str, EnvVar] = {};
    for nm in sorted(specs.keys()) {
        nd = EnvVar(name=nm, raw=specs[nm]);
        g[nm] = nd;
    }
    return g;
}

def link(g: dict[str, EnvVar], lhs: str, rhs: str) -> bool {
    # unknown ids are tolerated: return False, no edge created
    if lhs not in g or rhs not in g {
        return False;
    }
    g[lhs] +>:Dep:+> g[rhs];
    return True;
}

def visit_order(g: dict[str, EnvVar], name: str) -> list[str] {
    # DFS visit order from a var; empty list for unknown id
    if name not in g {
        return [];
    }
    wk = g[name] spawn Collect(claimed={}, order=[]);
    return wk.order;
}

def resolution_order(g: dict[str, EnvVar], name: str) -> list[str] {
    # dependencies-first order (reverse of DFS discovery)
    ord: list[str] = visit_order(g, name);
    out: list[str] = [];
    i: int = len(ord) - 1;
    while i >= 0 {
        out.append(ord[i]);
        i -= 1;
    }
    return out;
}

def _expand(g: dict[str, EnvVar], nd: EnvVar, memo: dict[str, str], stack: list[str]) -> str {
    # non-recursive expansion: a var seen on the current stack resolves to ""
    if nd.name in memo {
        return memo[nd.name];
    }
    if nd.name in stack {
        memo[nd.name] = "";
        return "";
    }
    stack.append(nd.name);
    raw: str = nd.raw;
    out: str = "";
    i: int = 0;
    while i < len(raw) {
        if raw[i] == "$" {
            j: int = i + 1;
            nm: str = "";
            while j < len(raw) and raw[j].isalnum() {
                nm += raw[j];
                j += 1;
            }
            if nm != "" and nm in g {
                out += _expand(g, g[nm], memo, stack);
            } else {
                out += raw[i:i + j - i];
            }
            i = j;
        } else {
            out += raw[i];
            i += 1;
        }
    }
    stack.pop();
    memo[nd.name] = out;
    return out;
}

def resolve_var(g: dict[str, EnvVar], name: str) -> str | None {
    # public API: None for unknown id, expanded value otherwise
    if name not in g {
        return None;
    }
    memo: dict[str, str] = {};
    stack: list[str] = [];
    return _expand(g, g[name], memo, stack);
}

test "basic_forward_expansion" {
    g = make_env({"ORACLE_HOME": "/opt/oracle", "LD_LIBRARY_PATH": "$ORACLE_HOME/lib"});
    assert link(g, "LD_LIBRARY_PATH", "ORACLE_HOME");
    assert resolve_var(g, "ORACLE_HOME") == "/opt/oracle";
    assert resolve_var(g, "LD_LIBRARY_PATH") == "/opt/oracle/lib";
    assert sorted(resolution_order(g, "LD_LIBRARY_PATH")) == ["LD_LIBRARY_PATH", "ORACLE_HOME"];
}}

test "self_reference_stops_not_blows_up" {
    # JENKINS-33239: PATH=path1:$PATH must not loop forever
    g = make_env({"PATH": "path1:$PATH"});
    assert link(g, "PATH", "PATH");
    assert resolve_var(g, "PATH") == "path1:";
}}

test "diamond_revisit_claimed_once" {
    g = make_env({"A": "a", "B": "$A-b", "C": "$A-c", "D": "$B-$C"});
    assert link(g, "B", "A");
    assert link(g, "C", "A");
    assert link(g, "D", "B");
    assert link(g, "D", "C");
    ord = visit_order(g, "D");
    # A is reachable via two paths but visited exactly once
    assert len(ord) == 4;
    assert ord.count("A") == 1;
    assert resolve_var(g, "D") == "a-b-a-c";
}}

test "unknown_id_tolerated" {
    g = make_env({"X": "x"});
    assert link(g, "X", "MISSING") == False;
    assert link(g, "MISSING", "X") == False;
    assert resolve_var(g, "MISSING") == None;
    assert visit_order(g, "MISSING") == [];
}}

test "unresolved_refs_kept_literal" {
    g = make_env({"Y": "$NOPE/later"});
    assert resolve_var(g, "Y") == "$NOPE/later";
}}

test "adversarial_insertion_order" {
    # edges inserted so shallow revisit fires before deeper first visit
    g = make_env({"R": "$S-$S", "S": "$T", "T": "deep"});
    assert link(g, "S", "T");
    assert link(g, "R", "S");
    assert link(g, "R", "S");
    assert resolve_var(g, "R") == "deep-deep";
    ord = visit_order(g, "R");
    assert ord.count("S") == 1;
}}
