# iss_NewGraphEnvironment__link__227.jac

node WSG {
    has code: str;
    has persisted: bool = False;
    has blocking_dams: int = 0;
    has access: str = "uncomputed";
    has mapping_code: str = "";
}

edge DrainsTo {}

obj Environment {
    has groups: dict[str, WSG] = {};
}

walker DownstreamClosure {
    has claimed: dict[str, bool] = {};
    has found: list[WSG] = [];

    can collect with WSG entry {
        if here.code in self.claimed {
            skip;
        }
        self.claimed[here.code] = True;
        print(here.code);
        for kid in [here ->:DrainsTo:->][?:WSG] {
            self.found.append(kid);
            visit :0: [kid];
        }
    }
}

def new_environment() -> Environment {
    return Environment();
}

def ensure_wsg(env: Environment, code: str) -> WSG {
    if code in env.groups {
        return env.groups[code];
    }
    group = WSG(code=code);
    env.groups[code] = group;
    return group;
}

def link_downstream(
    env: Environment,
    upstream_code: str,
    downstream_code: str
) {
    upstream = ensure_wsg(env, upstream_code);
    downstream = ensure_wsg(env, downstream_code);
    upstream +>:DrainsTo:+> downstream;
}

def persist_wsg(
    env: Environment,
    code: str,
    blocking_dams: int = 0
) {
    group = ensure_wsg(env, code);
    group.persisted = True;
    group.blocking_dams = blocking_dams;
    group.mapping_code = code;
    if blocking_dams > 0 {
        group.access = "blocked";
    } else {
        group.access = "open";
    }
}

def downstream_groups(env: Environment, code: str) -> list[WSG] {
    if code not in env.groups {
        return [];
    }
    focus = env.groups[code];
    claimed: dict[str, bool] = {};
    claimed[focus.code] = True;
    w = focus spawn DownstreamClosure(claimed=claimed, found=[]);
    return w.found;
}

def downstream_ready(env: Environment, code: str) -> bool {
    for group in downstream_groups(env, code) {
        if group.persisted == False {
            return False;
        }
    }
    return True;
}

def downstream_dam_count(env: Environment, code: str) -> int {
    total = 0;
    for group in downstream_groups(env, code) {
        if group.persisted {
            total += group.blocking_dams;
        }
    }
    return total;
}

def run_wsg_one(
    env: Environment,
    code: str,
    blocking_dams: int = 0
) -> bool {
    group = ensure_wsg(env, code);
    if downstream_ready(env, code) == False {
        print("downstream state incomplete");
        return False;
    }
    group.persisted = True;
    group.blocking_dams = blocking_dams;
    group.mapping_code = code;
    if blocking_dams + downstream_dam_count(env, code) > 0 {
        group.access = "blocked";
    } else {
        group.access = "open";
    }
    return True;
}

test "diamond closure skips revisit" {
    env = new_environment();
    link_downstream(env, "A", "B");
    link_downstream(env, "A", "C");
    link_downstream(env, "C", "D");
    link_downstream(env, "B", "D");

    assert (downstream_ready(env, "A") == False);
    persist_wsg(env, "D", 1);
    persist_wsg(env, "C");
    persist_wsg(env, "B");
    assert (downstream_ready(env, "A") == True);

    codes: list[str] = [];
    for group in downstream_groups(env, "A") {
        codes.append(group.code);
    }
    assert (sorted(codes) == ["B", "C", "D"]);
    assert (downstream_dam_count(env, "A") == 1);
}

test "unknown id is tolerated" {
    env = new_environment();
    assert (downstream_groups(env, "missing") == []);
    assert (downstream_ready(env, "missing") == True);
    assert (run_wsg_one(env, "missing") == True);
    assert (ensure_wsg(env, "missing").persisted == True);
}

test "guard rejects an unpersisted downstream group" {
    env = new_environment();
    link_downstream(env, "UP", "DOWN");

    assert (run_wsg_one(env, "UP") == False);
    assert (ensure_wsg(env, "UP").persisted == False);

    persist_wsg(env, "DOWN", 2);
    assert (run_wsg_one(env, "UP") == True);
    assert (ensure_wsg(env, "UP").access == "blocked");
    assert (downstream_dam_count(env, "UP") == 2);
}

test "cycle claim map preserves completion" {
    env = new_environment();
    link_downstream(env, "X", "Y");
    link_downstream(env, "Y", "X");
    persist_wsg(env, "Y", 1);

    assert (downstream_ready(env, "X") == True);
    assert (run_wsg_one(env, "X") == True);
    assert (downstream_dam_count(env, "X") == 1);
}
