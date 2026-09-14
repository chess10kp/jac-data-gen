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
