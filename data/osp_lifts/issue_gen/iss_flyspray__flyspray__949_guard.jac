# flyspray/flyspray#949: nested-set (Celko) category tree, multi-rooted per project,
# lifted to idiomatic Jac OSP. Supports update of fields, reorder, and delete
# with promotion of orphans.

node Category {
    has cid: str;
    has name: str;
    has owner: str = "";
    has show_in_list: bool = True;
    has lft: int = 0;
    has rgt: int = 0;
    has project_id: int = 0;
}

edge child_of {
    has depth: int = 0;
}

def find_root(graph_root: Category) -> Category | None {
    return graph_root;
}

# walk subtree rooted at nd, DFS pre-order, cycle-safe
def subtree_nodes(nd: Category) -> list[Category] {
    out: list[Category] = [];
    seen: dict[str, bool] = {};
    stack: list[Category] = [nd];
    while len(stack) {
        cur = stack.pop();
        if cur.cid in seen { continue; }
        seen[cur.cid] = True;
        out.append(cur);
        kids: list[Category] = [cur ->:child_of:->][?:Category];
        i = len(kids) - 1;
        while i >= 0 {
            stack.append(kids[i]);
            i -= 1;
        }
    }
    return out;
}

# relabel lft/rgt of every category under each root of the project via DFS
def relabel(begins: list[Category]) -> None {
    counter: dict[str, int] = {"n": 1};
    seen: dict[str, bool] = {};
    for rt in begins {
        _label(rt, counter, seen);
    }
}

def _label(nd: Category, counter: dict[str, int], seen: dict[str, bool]) -> None {
    if nd.cid in seen { return; }
    seen[nd.cid] = True;
    nd.lft = counter["n"];
    counter["n"] += 1;
    kids: list[Category] = [nd ->:child_of:->][?:Category];
    for k in kids {
        _label(k, counter, seen);
    }
    nd.rgt = counter["n"];
    counter["n"] += 1;
}

# update fields; cascade hide to descendants when hidden
walker UpdateCategory {
    can go with Category entry {
        here.name = self.new_name;
        here.owner = self.new_owner;
        if self.show_in_list == False {
            here.show_in_list = False;
            for d in subtree_nodes(here) {
                d.show_in_list = False;
            }
        }
        else {
            here.show_in_list = True;
        }
        print("updated " + here.cid);
        disengage;
    }
    has new_name: str;
    has new_owner: str;
    has show_in_list: bool = True;
}

# delete node; promote its children one level up (flyspray promotion route)
def delete_category(target: Category) -> bool {
    parent: list[Category] = [: Category ->:child_of:-> :Category :];
    par: Category | None = None;
    for p in parent {
        for c in [p ->:child_of:->][?:Category] {
            if c.cid == target.cid { par = p; break; }
        }
        if par != None { break; }
    }
    kids: list[Category] = [target ->:child_of:->][?:Category];
    for k in kids {
        if par != None {
            par +>:child_of:+> k;
        }
    }
    # disconnect all inbound edges then orphan the node from any traversal
    for p in parent {
        vs: list[Category] = [p ->:child_of:->][?:Category];
        keep: list[Category] = [];
        for v in vs {
            if v.cid != target.cid { keep.append(v); }
        }
        if len(keep) != len(vs) {
            for v in keep {
                p +>:child_of:+> v;
            }
        }
    }
    print("deleted " + target.cid);
    return True;
}

def list_categories(graph_root: Category) -> list[Category] {
    return subtree_nodes(graph_root);
}

def update_category(root_cat: Category, new_name: str, new_owner: str, show: bool) -> None {
    root_cat spawn UpdateCategory(new_name=new_name, new_owner=new_owner, show_in_list=show);
}

test "diamond revisit does not loop" {
    a = Category(cid="a", name="a");
    b = Category(cid="b", name="b");
    c = Category(cid="c", name="c");
    d = Category(cid="d", name="d");
    root ++> a;
    a +>:child_of:+> b;
    a +>:child_of:+> c;
    b +>:child_of:+> d;
    c +>:child_of:+> d;
    ns = subtree_nodes(a);
    assert len(ns) == 4;
    ids: list[str] = [];
    for n in ns { ids.append(n.cid); }
    assert sorted(ids) == ["a", "b", "c", "d"];
}

test "relabel nested set bounds" {
    rt = Category(cid="r", name="root");
    m = Category(cid="m", name="mid");
    lf = Category(cid="lf", name="leaf");
    rt +>:child_of:+> m;
    m +>:child_of:+> lf;
    relabel([rt]);
    assert rt.lft == 1;
    assert lf.lft == 2;
    assert lf.rgt == 3;
    assert m.rgt == 4;
    assert rt.rgt == 5;
}

test "delete promotes orphans" {
    rt = Category(cid="r2", name="root");
    p = Category(cid="p", name="par");
    k = Category(cid="k", name="kid");
    rt +>:child_of:+> p;
    p +>:child_of:+> k;
    ok = delete_category(p);
    assert ok;
    kids2: list[Category] = [rt ->:child_of:->][?:Category];
    found = False;
    for c in kids2 {
        if c.cid == "k" { found = True; }
    }
    assert found;
}

test "unknown id tolerated by list" {
    rt = Category(cid="rx", name="root");
    ns = list_categories(rt);
    ok = False;
    for n in ns {
        if n.cid == "rx" { ok = True; }
    }
    assert ok;
    assert len(ns) == 1;
}

test "hide cascades to descendants" {
    rt = Category(cid="t", name="root");
    s = Category(cid="s", name="sub");
    rt +>:child_of:+> s;
    update_category(rt, "root2", "bob", False);
    assert rt.show_in_list == False;
    assert s.show_in_list == False;
    assert rt.name == "root2";
}
