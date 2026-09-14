node Environment {}
node WSG {
    has wsg_id: str;
    has streams_rows: int = 0;
    has habitat_rows: int = 0;
    has accessible: bool = True;
    has mapping_code: str = "1:1";
}
node Barrier {
    has barrier_id: str;
    has blocking: bool = True;
}
edge CONTAINS {}
edge DOWNSTREAM {}
edge HAS_BARRIER {}

walker AccessScan {
    has target_id: str;
    has blocked: bool = False;
    has claimed: dict[str, bool] = {};

    can begin with Environment entry {
        print("access scan " + self.target_id);
        for candidate in [here ->:CONTAINS:->][?:WSG] {
            if candidate.wsg_id == self.target_id {
                visit :0: [candidate];
            }
        }
    }

    can inspect_wsg with WSG entry {
        if here.wsg_id in self.claimed {
            skip;
        }
        self.claimed[here.wsg_id] = True;
        for barrier in [here ->:HAS_BARRIER:->][?:Barrier] {
            visit :0: [barrier];
        }
        for child in [here ->:DOWNSTREAM:->][?:WSG] {
            visit :0: [child];
        }
    }

    can inspect_barrier with Barrier entry {
        print("barrier " + here.barrier_id);
        if here.blocking {
            self.blocked = True;
        }
    }
}

def new_environment() -> Environment {
    return Environment();
}

def add_wsg(
    env: Environment,
    wsg_id: str,
    streams_rows: int = 0,
    habitat_rows: int = 0
) -> WSG {
    wsg = WSG(
        wsg_id=wsg_id,
        streams_rows=streams_rows,
        habitat_rows=habitat_rows
    );
    env +>:CONTAINS:+> wsg;
    return wsg;
}

def add_barrier(wsg: WSG, barrier_id: str, blocking: bool = True) -> Barrier {
    barrier = Barrier(barrier_id=barrier_id, blocking=blocking);
    wsg +>:HAS_BARRIER:+> barrier;
    return barrier;
}

def find_wsg(env: Environment, wsg_id: str) -> WSG | None {
    for wsg in [env ->:CONTAINS:->][?:WSG] {
        if wsg.wsg_id == wsg_id {
            return wsg;
        }
    }
    return None;
}

def connect_downstream_by_id(
    env: Environment,
    upstream_id: str,
    downstream_id: str
) -> bool {
    upstream: WSG | None = find_wsg(env, upstream_id);
    downstream: WSG | None = find_wsg(env, downstream_id);
    if upstream is None {
        return False;
    }
    if downstream is None {
        return False;
    }
    upstream +>:DOWNSTREAM:+> downstream;
    return True;
}

def recompute_access(env: Environment) -> dict[str, bool] {
    result: dict[str, bool] = {};
    for wsg in [env ->:CONTAINS:->][?:WSG] {
        w = env spawn AccessScan(
            target_id=wsg.wsg_id,
            blocked=False,
            claimed={}
        );
        wsg.accessible = not w.blocked;
        result[wsg.wsg_id] = wsg.accessible;
    }
    return result;
}

def post_consolidate_recompute(env: Environment) -> dict[str, str] {
    recompute_access(env);
    result: dict[str, str] = {};
    for wsg in [env ->:CONTAINS:->][?:WSG] {
        if wsg.accessible {
            wsg.mapping_code = "1:1";
        } else {
            wsg.mapping_code = "0:0";
        }
        result[wsg.wsg_id] = wsg.mapping_code;
    }
    return result;
}

def recompute_mapping_code(env: Environment) -> dict[str, str] {
    return post_consolidate_recompute(env);
}

def mapping_code_for(env: Environment, wsg_id: str) -> str {
    for wsg in [env ->:CONTAINS:->][?:WSG] {
        if wsg.wsg_id == wsg_id {
            return wsg.mapping_code;
        }
    }
    return "";
}
