"""ansible/ansible#17806 — recursive hostvar templating."""

node Host {
    has host_id: str;
    has vars: dict[str, str] = {};
}

node Inventory {}

edge HostLink {}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has ids: list[str] = [];

    can start with Inventory entry {
        kids: list[Host] = [];
        for ch in [here ->:HostLink:->][?:Host] {
            kids.append(ch);
        }
        print("reach inventory");
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }

    can walk with Host entry {
        if here.host_id in self.claimed {
            skip;
        }
        self.claimed[here.host_id] = True;
        self.ids.append(here.host_id);
        print("reach ", here.host_id);
        kids: list[Host] = [];
        for ch in [here ->:HostLink:->][?:Host] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def is_tmpl(raw: str) -> bool {
    return "{{" in raw and "}}" in raw;
}

def tmpl_inner(raw: str) -> str {
    start = raw.find("{{") + 2;
    end = raw.find("}}");
    return raw[start:end].strip();
}

def tmpl_kind(inner: str) -> str {
    colon = inner.find(":");
    if colon < 0 {
        return "LIT";
    }
    return inner[:colon];
}

def tmpl_arg(inner: str) -> str {
    colon = inner.find(":");
    if colon < 0 {
        return inner;
    }
    return inner[colon + 1:];
}

def ref_host(payload: str) -> str {
    colon = payload.find(":");
    if colon < 0 {
        return payload;
    }
    return payload[:colon];
}

def ref_key(payload: str) -> str {
    colon = payload.find(":");
    if colon < 0 {
        return "";
    }
    return payload[colon + 1:];
}

def index_hosts(inv: Inventory) -> dict[str, Host] {
    table: dict[str, Host] = {};
    for h in [inv ->:HostLink:->][?:Host] {
        table[h.host_id] = h;
    }
    return table;
}

def host_order(inv: Inventory) -> list[str] {
    order: list[str] = [];
    for h in [inv ->:HostLink:->][?:Host] {
        order.append(h.host_id);
    }
    return order;
}

def resolve_core(
    table: dict[str, Host],
    order: list[str],
    host_id: str,
    key: str,
    claim: dict[str, bool]
) -> str | list[str] {
    token = host_id + ":" + key;
    if token in claim {
        return "";
    }
    claim[token] = True;
    if host_id not in table {
        return "";
    }
    host = table[host_id];
    if key not in host.vars {
        return "";
    }
    raw = host.vars[key];
    if not is_tmpl(raw) {
        return raw;
    }
    inner = tmpl_inner(raw);
    kind = tmpl_kind(inner);
    arg = tmpl_arg(inner);
    if kind == "EXTRACT" {
        vals: list[str] = [];
        for hid in order {
            item = resolve_core(table, order, hid, arg, claim);
            vals.append(item as str);
        }
        return vals;
    }
    if kind == "REF" {
        rh = ref_host(arg);
        rk = ref_key(arg);
        return resolve_core(table, order, rh, rk, claim);
    }
    return raw;
}

def create_inventory(host_ids: list[str]) -> Inventory {
    inv = Inventory();
    root ++> inv;
    for hid in host_ids {
        h = Host(host_id=hid);
        inv +>: HostLink :+> h;
    }
    return inv;
}

def set_host_var(inv: Inventory, host_id: str, key: str, value: str) {
    table = index_hosts(inv);
    if host_id in table {
        table[host_id].vars[key] = value;
    }
}

def broadcast_var(inv: Inventory, key: str, value: str) {
    table = index_hosts(inv);
    order = host_order(inv);
    for hid in order {
        if hid in table {
            table[hid].vars[key] = value;
        }
    }
}

def resolve_var(inv: Inventory, host_id: str, key: str) -> str | list[str] {
    table = index_hosts(inv);
    order = host_order(inv);
    claim: dict[str, bool] = {};
    return resolve_core(table, order, host_id, key, claim);
}

def lookup_hostvar(inv: Inventory, host_id: str, key: str) -> str | list[str] {
    return resolve_var(inv, host_id, key);
}

def extract_vars(inv: Inventory, host_ids: list[str], key: str) -> list[str] {
    out: list[str] = [];
    for hid in host_ids {
        item = resolve_var(inv, hid, key);
        out.append(item as str);
    }
    return out;
}

def wire_hosts(inv: Inventory, parent_id: str, child_id: str) {
    table = index_hosts(inv);
    if parent_id in table {
        if child_id in table {
            p = table[parent_id];
            c = table[child_id];
            p +>: HostLink :+> c;
        }
    }
}

def reachable_host_ids(inv: Inventory) -> list[str] {
    w = inv spawn ReachWalker(claimed={});
    out: list[str] = [];
    for hid in w.ids {
        out.append(hid);
    }
    return sorted(out);
}
