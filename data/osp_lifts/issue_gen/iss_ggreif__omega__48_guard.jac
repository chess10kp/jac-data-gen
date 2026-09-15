"""ggreif/omega#48 - refinement failure with recursive Equal."""

node Env {
    has next_cid: int = 0;
}

node Equal {
    has cid: str;
    has name: str;
    has body: str;
    has exclude: list[str] = [];
}

edge InEnv {}

def var_in_exclude(exclude: list[str], var: str) -> bool {
    for x in exclude {
        if x == var {
            return True;
        }
    }
    return False;
}

def find_equal(env: Env, name: str) -> Equal | None {
    for eq in [env ->:InEnv:->][?:Equal] {
        if eq.name == name {
            return eq;
        }
    }
    return None;
}

def next_cid(env: Env) -> str {
    n = env.next_cid;
    env.next_cid = n + 1;
    return "eq_" + str(n);
}

def new_env() -> Env {
    e = Env();
    root ++> e;
    return e;
}

def add_equal(env: Env, name: str, exclude: list[str], body: str) -> None {
    cid = next_cid(env);
    eq = Equal(cid=cid, name=name, body=body, exclude=exclude);
    env +>:InEnv:+> eq;
    root ++> eq;
}

def has_equal(env: Env, name: str) -> bool {
    target = find_equal(env, name);
    return target is not None;
}

def refine(env: Env, equal_name: str, var: str) -> bool {
    target = find_equal(env, equal_name);
    if target is None {
        return False;
    }
    w = target spawn RefineWalker(env=env, var_name=var);
    return w.ok;
}

walker RefineWalker {
    has env: Env;
    has var_name: str;
    has claimed: dict[str, bool] = {};
    has ok: bool = True;

    can step with Equal entry {
        if here.cid in self.claimed {
            self.ok = False;
            skip;
        }
        self.claimed[here.cid] = True;
        print("refine", here.name, self.var_name);
        if self.var_name == here.body {
            print("match", here.name);
        } elif var_in_exclude(here.exclude, self.var_name) {
            self.ok = False;
            print("exclude", here.name, self.var_name);
            disengage;
        } else {
            nxt = find_equal(self.env, here.body);
            if nxt is not None {
                visit :0: [nxt];
            } else {
                self.ok = False;
                print("dead", here.name, here.body);
                disengage;
            }
        }
    }
}

test "issue48_self_ref" {
    e = new_env();
    ex: list[str] = [];
    ex.append("_b");
    ex.append("_c");
    add_equal(e, "Eq", ex, "_c");
    assert refine(e, "Eq", "_c");;
}

test "exclude_blocks_non_body" {
    e = new_env();
    ex: list[str] = [];
    ex.append("_c");
    add_equal(e, "E", ex, "_d");
    assert not refine(e, "E", "_c");;
}

test "unknown_equal_tolerance" {
    e = new_env();
    ex: list[str] = [];
    ex.append("_a");
    add_equal(e, "Known", ex, "_a");
    assert not has_equal(e, "Missing");;
    assert not refine(e, "Missing", "_a");;
}

test "diamond_revisit_cycle" {
    e = new_env();
    add_equal(e, "Top", [], "Mid");
    add_equal(e, "Mid", [], "Leaf");
    add_equal(e, "Leaf", [], "Mid");
    assert not refine(e, "Top", "_y");;
}

test "nested_body_resolve" {
    e = new_env();
    add_equal(e, "Inner", [], "_v");
    add_equal(e, "Outer", [], "Inner");
    assert refine(e, "Outer", "_v");;
}
