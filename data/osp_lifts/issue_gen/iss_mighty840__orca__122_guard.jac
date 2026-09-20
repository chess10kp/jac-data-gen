"""mighty840/orca#122 — depends_on start-order plus wait_for readiness gates."""

node Anchor {}

node Service {
    has name: str;
}

edge DependsOn {}

walker TopoWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step_anchor with Anchor entry {
        kids: list[Service] = [];
        for ch in [here ->>] {
            s = ch as Service;
            kids.append(s);
        }
        for kid in kids {
            visit :0: [kid];
        }
        print("topo", self.order);
        disengage;
    }

    can step_svc with Service entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        deps: list[Service] = [];
        for dep in [here ->:DependsOn:->][?:Service] {
            deps.append(dep);
        }
        for dep in deps {
            visit :0: [dep];
        }
        self.order.append(here.name);
    }
}

walker PingWalker {
    can ping entry {
        print("ping", "orca122");
        disengage;
    }
}

def build_graph(names: list[str], depends: dict[str, list[str]]) -> Anchor {
    anchor = Anchor();
    root ++> anchor;
    by_name: dict[str, Service] = {};
    sorted_names: list[str] = [];
    for n in names {
        sorted_names.append(n);
    }
    sorted_names.sort();
    for n in sorted_names {
        s = Service(name=n);
        by_name[n] = s;
        anchor ++> s;
    }
    dep_keys: list[str] = [];
    for k in depends {
        dep_keys.append(k);
    }
    dep_keys.sort();
    for svc_name in dep_keys {
        if svc_name not in by_name {
            continue;
        }
        raw_deps: list[str] | None = depends[svc_name];
        dep_list: list[str] = [];
        if raw_deps is not None {
            for d in raw_deps {
                dep_list.append(d);
            }
        }
        dep_list.sort();
        svc = by_name[svc_name];
        for dep_name in dep_list {
            if dep_name not in by_name {
                continue;
            }
            dep = by_name[dep_name];
            svc +>:DependsOn:+> dep;
        }
    }
    return anchor;
}

def topo_start_order(names: list[str], depends: dict[str, list[str]]) -> list[str] {
    anchor = build_graph(names, depends);
    w = anchor spawn TopoWalker(claimed={}, order=[]);
    out: list[str] = [];
    for n in w.order {
        out.append(n);
    }
    return out;
}

def parse_wait_spec(spec: str) -> dict[str, object] {
    parts: list[str] = [];
    buf: str = "";
    for i in range(len(spec)) {
        c = spec[i];
        if c == ":" {
            parts.append(buf);
            buf = "";
        } else {
            buf = buf + c;
        }
    }
    parts.append(buf);
    result: dict[str, object] = {};
    result["target"] = parts[0];
    result["check"] = "tcp";
    result["port"] = 0;
    result["timeout_s"] = 30;
    if len(parts) > 1 {
        result["check"] = parts[1];
    }
    if len(parts) > 2 {
        result["port"] = int(parts[2]);
    }
    if len(parts) > 3 {
        tout = parts[3];
        if tout.endswith("s") {
            tout = tout[0 : len(tout) - 1];
        }
        result["timeout_s"] = int(tout);
    }
    return result;
}

def pending_waits(waits: list[str], ready: dict[str, bool]) -> list[str] {
    pending: list[str] = [];
    sorted_waits: list[str] = [];
    for w in waits {
        sorted_waits.append(w);
    }
    sorted_waits.sort();
    for spec in sorted_waits {
        parsed = parse_wait_spec(spec);
        target = parsed["target"] as str;
        is_ready = False;
        if target in ready {
            is_ready = ready[target];
        }
        if not is_ready {
            pending.append(spec);
        }
    }
    return pending;
}

def can_start(
    name: str,
    depends: dict[str, list[str]],
    waits: dict[str, list[str]],
    started: dict[str, bool],
    ready: dict[str, bool>,
) -> bool {
    if name in started and started[name] {
        return False;
    }
    dep_list: list[str] = [];
    if name in depends {
        raw = depends[name];
        if raw is not None {
            for d in raw {
                dep_list.append(d);
            }
        }
    }
    for dep in dep_list {
        dep_started = False;
        if dep in started {
            dep_started = started[dep];
        }
        if not dep_started {
            return False;
        }
    }
    wait_list: list[str] = [];
    if name in waits {
        raw_w = waits[name];
        if raw_w is not None {
            for w in raw_w {
                wait_list.append(w);
            }
        }
    }
    pend = pending_waits(wait_list, ready);
    if len(pend) > 0 {
        return False;
    }
    return True;
}

with entry {
    demo_deps: dict[str, list[str]] = {};
    demo_deps["erp-frontend"] = ["erp-backend"];
    print("entry", topo_start_order(["erp-frontend", "erp-backend"], demo_deps));
    root spawn PingWalker;
}

test "topo_depends_before_dependent" {
    deps: dict[str, list[str]] = {};
    deps["fe"] = ["be"];
    order = topo_start_order(["fe", "be"], deps);
    assert order == ["be", "fe"];
}

test "diamond_revisit_stable_order" {
    deps: dict[str, list[str]] = {};
    deps["fe"] = ["api", "db"];
    deps["api"] = ["cache"];
    deps["db"] = ["cache"];
    order = topo_start_order(["fe", "api", "db", "cache"], deps);
    assert order.index("cache") < order.index("api");
    assert order.index("cache") < order.index("db");
    assert order.index("api") < order.index("fe");
    assert order.index("db") < order.index("fe");
}

test "unknown_dep_id_tolerated" {
    deps: dict[str, list[str]] = {};
    deps["fe"] = ["ghost"];
    order = topo_start_order(["fe"], deps);
    assert order == ["fe"];
}

test "parse_wait_spec_tcp_port" {
    parsed = parse_wait_spec("erp-backend:tcp:8000");
    assert parsed["target"] == "erp-backend";
    assert parsed["check"] == "tcp";
    assert parsed["port"] == 8000;
}

test "pending_waits_sorted_unready" {
    ready: dict[str, bool] = {};
    ready["erp-backend"] = False;
    pend = pending_waits(["erp-db:tcp:3306", "erp-backend:tcp:8000"], ready);
    assert pend == ["erp-backend:tcp:8000", "erp-db:tcp:3306"];
}

test "can_start_requires_started_dep_and_ready_target" {
    depends: dict[str, list[str]] = {};
    depends["fe"] = ["be"];
    waits: dict[str, list[str]] = {};
    waits["fe"] = ["be:tcp:8000"];
    started: dict[str, bool] = {};
    started["be"] = True;
    ready: dict[str, bool] = {};
    ready["be"] = True;
    assert can_start("fe", depends, waits, started, ready) is True;
}
