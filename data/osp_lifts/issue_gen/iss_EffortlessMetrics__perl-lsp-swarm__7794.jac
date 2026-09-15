"""Compose Moose extends/with relationships over canonical project facts.

EffortlessMetrics/perl-lsp-swarm#7794
"""

node Package {
    has pkg_id: str;
    has explicit_methods: list[str] = [];
    has with_role_ids: list[str] = [];
    has with_role_orders: list[int] = [];
}

edge Extends {}

edge With {
    has order_idx: int = 0;
}

obj MooseFactsGraph {
    has by_id: dict[str, Package] = {};

    def ensure_pkg(pkg_id: str) -> Package {
        if pkg_id in self.by_id {
            return self.by_id[pkg_id];
        }
        nd = Package(pkg_id=pkg_id);
        self.by_id[pkg_id] = nd;
        root ++> nd;
        return nd;
    }

    def link_extends(child_id: str, parent_id: str) -> None {
        child = self.ensure_pkg(child_id);
        parent = self.ensure_pkg(parent_id);
        child +>:Extends:+> parent;
    }

    def link_with(consumer_id: str, role_id: str, order_idx: int) -> None {
        consumer = self.ensure_pkg(consumer_id);
        role = self.ensure_pkg(role_id);
        consumer.with_role_ids.append(role_id);
        consumer.with_role_orders.append(order_idx);
        consumer +>:With:order_idx=order_idx:+> role;
    }
}

walker TransitiveWalker {
    has claimed: dict[str, bool] = {};
    has ordered: list[str] = [];

    can step with Package entry {
        if here.pkg_id in self.claimed { skip; }
        self.claimed[here.pkg_id] = True;
        self.ordered.append(here.pkg_id);
        print(f"visit {here.pkg_id}");
        nexts: list[Package] = [];
        for par in [here ->:Extends:->][?:Package] {
            nexts.append(par);
        }
        for rol in [here ->:With:->][?:Package] {
            nexts.append(rol);
        }
        if len(nexts) > 0 {
            visit nexts;
        } else {
            disengage;
        }
    }
}

def sort_by_order(pairs: list[tuple[str, int]]) -> list[tuple[str, int]] {
    arr: list[tuple[str, int]] = pairs;
    i: int = 0;
    while i < len(arr) {
        j: int = i + 1;
        while j < len(arr) {
            if arr[j][1] < arr[i][1] {
                tmp = arr[i];
                arr[i] = arr[j];
                arr[j] = tmp;
            }
            j += 1;
        }
        i += 1;
    }
    return arr;
}

def inheritance_parents(g: MooseFactsGraph, consumer_id: str) -> list[str] {
    if consumer_id not in g.by_id {
        return [];
    }
    nd = g.by_id[consumer_id];
    parents: list[str] = [];
    for par in [nd ->:Extends:->][?:Package] {
        parents.append(par.pkg_id);
    }
    return sorted(parents);
}

def role_composition(g: MooseFactsGraph, consumer_id: str) -> list[tuple[str, int]] {
    if consumer_id not in g.by_id {
        return [];
    }
    nd = g.by_id[consumer_id];
    pairs: list[tuple[str, int]] = [];
    i: int = 0;
    while i < len(nd.with_role_ids) {
        pairs.append((nd.with_role_ids[i], nd.with_role_orders[i]));
        i += 1;
    }
    return sort_by_order(pairs);
}

def compose_transitive_closure(g: MooseFactsGraph, consumer_id: str) -> list[str] {
    if consumer_id not in g.by_id {
        return [];
    }
    start = g.by_id[consumer_id];
    w = start spawn TransitiveWalker(claimed={}, ordered=[]);
    return w.ordered;
}

def resolve_method_precedence(
    g: MooseFactsGraph,
    consumer_id: str,
    provided_by: dict[str, list[str]],
) -> list[str] {
    if consumer_id not in g.by_id {
        return [];
    }
    out: list[str] = [];
    seen: dict[str, bool] = {};
    cnd = g.by_id[consumer_id];
    for m in cnd.explicit_methods {
        if m not in seen {
            seen[m] = True;
            out.append(m);
        }
    }
    roles = sort_by_order(role_composition(g, consumer_id));
    ri: int = len(roles) - 1;
    while ri >= 0 {
        rid = roles[ri][0];
        ri -= 1;
        if rid not in provided_by {
            continue;
        }
        srcs: list[str] = provided_by[rid];
        si: int = 0;
        while si < len(srcs) {
            m = srcs[si];
            si += 1;
            if m not in seen {
                seen[m] = True;
                out.append(m);
            }
        }
    }
    parents = inheritance_parents(g, consumer_id);
    pi: int = 0;
    while pi < len(parents) {
        pid = parents[pi];
        pi += 1;
        if pid not in provided_by {
            continue;
        }
        psrcs: list[str] = provided_by[pid];
        pj: int = 0;
        while pj < len(psrcs) {
            pm = psrcs[pj];
            pj += 1;
            if pm not in seen {
                seen[pm] = True;
                out.append(pm);
            }
        }
    }
    return out;
}
