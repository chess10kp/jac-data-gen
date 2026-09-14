# Oblikovati/Oblikovati#3069

node Point {
    has x: float;
    has y: float;
    has z: float;
}

node Element {
    has fid: str;
    has midpoint: Point;
    has rank_token: str = "";
}

edge ParentOf {}

walker GroupWalker {
    has parent_id: str;
    has claimed: dict[str, bool] = {};
    has kids: list[Element] = [];

    can step with Element entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        print("group:" + self.parent_id + ":" + here.fid);
        for kid in [here ->:ParentOf:->][?:Element] {
            if here.fid == self.parent_id {
                self.kids.append(kid);
            }
            visit :0: [kid];
        }
    }
}

walker CollectWalker {
    has claimed: dict[str, bool] = {};
    has found: list[Element] = [];

    can step with Element entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        self.found.append(here);
        print("collect:" + here.fid);
        for kid in [here ->:ParentOf:->][?:Element] {
            visit :0: [kid];
        }
    }
}

walker FindWalker {
    has target_id: str;
    has claimed: dict[str, bool] = {};
    has found: str = "";

    can step with Element entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        print("find:" + here.fid);
        if here.fid == self.target_id {
            self.found = here.rank_token;
        }
        for kid in [here ->:ParentOf:->][?:Element] {
            visit :0: [kid];
        }
    }
}

def edge_rank_point(item: Element) -> Point {
    return item.midpoint;
}

def less_point(left: Point, right: Point) -> bool {
    if left.x < right.x { return True; }
    if left.x > right.x { return False; }
    if left.y < right.y { return True; }
    if left.y > right.y { return False; }
    return left.z < right.z;
}

def migrate_rank_token(token: str) -> str {
    if token == "" { return ""; }
    if token.startswith("v2:") { return token; }
    return "v2:" + token;
}

def name_group(parent: Element) -> dict[str, str] {
    w = parent spawn GroupWalker(parent_id=parent.fid, claimed={});
    ordered: list[Element] = [];
    for kid in w.kids {
        pos: int = 0;
        while pos < len(ordered) {
            if less_point(edge_rank_point(kid), edge_rank_point(ordered[pos])) {
                break;
            }
            pos += 1;
        }
        ordered.insert(pos, kid);
    }
    answer: dict[str, str] = {};
    index: int = 0;
    for kid in ordered {
        token: str = "v2:" + str(index) + ":" + kid.fid;
        kid.rank_token = token;
        answer[kid.fid] = token;
        index += 1;
    }
    return answer;
}

def migrate_rank_tokens(graph_root: Element) -> int {
    w = graph_root spawn CollectWalker(claimed={});
    changed: int = 0;
    for item in w.found {
        old_token: str = item.rank_token;
        new_token: str = migrate_rank_token(old_token);
        if old_token != new_token {
            item.rank_token = new_token;
            changed += 1;
        }
    }
    return changed;
}

def lookup_name(graph_root: Element, fid: str) -> str {
    w = graph_root spawn FindWalker(target_id=fid, claimed={});
    return w.found;
}

test "diamond revisit and cycle migration" {
    root_node = Element(fid="root", midpoint=Point(x=0.0, y=0.0, z=0.0));
    left = Element(fid="left", midpoint=Point(x=1.0, y=0.0, z=0.0));
    right = Element(fid="right", midpoint=Point(x=2.0, y=0.0, z=0.0));
    shared = Element(fid="shared", midpoint=Point(x=3.0, y=0.0, z=0.0), rank_token="4:shared");
    tail = Element(fid="tail", midpoint=Point(x=4.0, y=0.0, z=0.0), rank_token="5:tail");
    root_node +>:ParentOf:+> left;
    root_node +>:ParentOf:+> right;
    left +>:ParentOf:+> shared;
    right +>:ParentOf:+> shared;
    shared +>:ParentOf:+> tail;
    tail +>:ParentOf:+> shared;
    names = name_group(root_node);
    assert (len(names) == 2);
    assert (names["left"] == "v2:0:left");
    assert (names["right"] == "v2:1:right");
    assert (migrate_rank_tokens(root_node) == 4);
    assert (lookup_name(root_node, "shared") == "v2:4:shared");
}

test "unknown identifiers are tolerated" {
    graph_root = Element(fid="only", midpoint=Point(x=1.0, y=2.0, z=3.0));
    assert (lookup_name(graph_root, "missing") == "");
    assert (migrate_rank_token("") == "");
}

test "migration is idempotent" {
    graph_root = Element(fid="item", midpoint=Point(x=1.0, y=2.0, z=3.0), rank_token="7:item");
    assert (migrate_rank_tokens(graph_root) == 1);
    assert (lookup_name(graph_root, "item") == "v2:7:item");
    assert (migrate_rank_tokens(graph_root) == 0);
}

test "empty sibling groups remain empty" {
    graph_root = Element(fid="leaf", midpoint=Point(x=0.0, y=0.0, z=0.0));
    names = name_group(graph_root);
    assert (len(names) == 0);
    assert (less_point(edge_rank_point(graph_root), edge_rank_point(graph_root)) == False);
}
