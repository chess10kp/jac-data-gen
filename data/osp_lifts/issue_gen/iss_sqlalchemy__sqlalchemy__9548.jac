"""sqlalchemy/sqlalchemy#9548 - wildcard relationship loader depth semantics."""

glob WILDCARD_TOKEN = "*";
glob RECURSIVE_WILDCARD_TOKEN = "**";

node Entity {
    has eid: str;
    has label: str;
}

edge Rel {}

walker LoadCollect {
    has claimed: dict[str, bool] = {};
    has max_depth: int;
    has cur_depth: int = 0;
    has out: list[str] = [];

    can collect with Entity entry {
        if here.eid in self.claimed {
            skip;
        }
        self.claimed[here.eid] = True;
        if self.cur_depth > 0 {
            self.out.append(here.eid);
        }
        print ["load", here.eid, self.cur_depth];
        if self.max_depth >= 0 and self.cur_depth >= self.max_depth {
            disengage;
        }
        kids: list[Entity] = [];
        for ch in [here ->:Rel:->][?:Entity] {
            kids.append(ch);
        }
        nd: int = self.cur_depth + 1;
        for kid in kids {
            kid spawn LoadCollect(
                claimed=self.claimed,
                max_depth=self.max_depth,
                cur_depth=nd,
                out=self.out
            );
        }
        disengage;
    }
}

def build_all_nodes -> dict[str, Entity] {
    store: dict[str, Entity] = {};
    p = Entity(eid="parent_p1", label="Parent");
    c1 = Entity(eid="child_c1", label="Child");
    c2 = Entity(eid="child_c2", label="Child");
    ot = Entity(eid="other_o1", label="OtherThing");
    sc = Entity(eid="sub_s1", label="SubChild");
    rd = Entity(eid="root_d", label="DiamondRoot");
    dl = Entity(eid="d_left", label="Left");
    dr = Entity(eid="d_right", label="Right");
    sh = Entity(eid="d_shared", label="Shared");
    dx = Entity(eid="d_x", label="DeepX");
    dy = Entity(eid="d_y", label="DeepY");
    store["parent_p1"] = p;
    store["child_c1"] = c1;
    store["child_c2"] = c2;
    store["other_o1"] = ot;
    store["sub_s1"] = sc;
    store["root_d"] = rd;
    store["d_left"] = dl;
    store["d_right"] = dr;
    store["d_shared"] = sh;
    store["d_x"] = dx;
    store["d_y"] = dy;
    p +>:Rel:+> c1;
    p +>:Rel:+> c2;
    p +>:Rel:+> ot;
    c1 +>:Rel:+> sc;
    rd +>:Rel:+> dl;
    rd +>:Rel:+> dr;
    dl +>:Rel:+> sh;
    dr +>:Rel:+> sh;
    sh +>:Rel:+> dx;
    sh +>:Rel:+> dy;
    return store;
}

def wire_graph_root(nodes: dict[str, Entity]) {
    root ++> nodes["parent_p1"];
    root ++> nodes["root_d"];
}

def token_is_valid(token: str) -> bool {
    if token == WILDCARD_TOKEN {
        return True;
    }
    if token == RECURSIVE_WILDCARD_TOKEN {
        return True;
    }
    return False;
}

def token_max_depth(token: str) -> int {
    if token == WILDCARD_TOKEN {
        return 1;
    }
    if token == RECURSIVE_WILDCARD_TOKEN {
        return -1;
    }
    raise ValueError(token);
}

def load_with_max_depth(root_eid: str, max_depth: int) -> list[str] {
    nodes = build_all_nodes();
    if not (root_eid in nodes) {
        return [];
    }
    start = nodes[root_eid];
    out: list[str] = [];
    claimed: dict[str, bool] = {};
    start spawn LoadCollect(
        claimed=claimed,
        max_depth=max_depth,
        cur_depth=0,
        out=out
    );
    out.sort();
    return out;
}

def wildcard_load_ids(root_eid: str, token: str) -> list[str] {
    md = token_max_depth(token);
    return load_with_max_depth(root_eid, md);
}

def legacy_selectin_star_ids(root_eid: str) -> list[str] {
    return load_with_max_depth(root_eid, -1);
}

def legacy_lazy_star_ids(root_eid: str) -> list[str] {
    return load_with_max_depth(root_eid, 1);
}

with entry {
    nodes = build_all_nodes();
    wire_graph_root(nodes);
    root spawn LoadCollect(claimed={}, max_depth=1, cur_depth=0, out=[]);
}
