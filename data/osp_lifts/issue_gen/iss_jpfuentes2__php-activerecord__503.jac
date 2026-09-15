"""Closure-table descendant queries — jpfuentes2/php-activerecord#503."""

node Category {
    has cid: int;
    has name: str;
}

edge Tree {}

edge Closure {
    has depth: int;
}

def find_category_by_cid(cid: int) -> Category | None {
    nodes: list[Category] = [root -->][?:Category];
    for nd in nodes {
        if nd.cid == cid {
            return nd;
        }
    }
    return None;
}

def add_category(cid: int, name: str) -> bool {
    if find_category_by_cid(cid) is not None {
        return False;
    }
    nd = Category(cid=cid, name=name);
    root ++> nd;
    nd +>:Closure(depth=0):+> nd;
    return True;
}

walker MaintainClosure {
    has child: Category;
    has depth: int;
    has claimed: dict[int, bool] = {};

    can rise with Category entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        dep: int = self.depth + 1;
        here +>:Closure(depth=dep):+> self.child;
        parents: list[Category] = [here <-:Tree:<-][?:Category];
        for p in parents {
            p spawn MaintainClosure(child=self.child, depth=dep, claimed={});
        }
        disengage;
    }
}

def link_parent_child(parent_id: int, child_id: int) -> bool {
    parent = find_category_by_cid(parent_id);
    child = find_category_by_cid(child_id);
    if parent is None or child is None {
        return False;
    }
    parent +>:Tree:+> child;
    parent spawn MaintainClosure(child=child, depth=0, claimed={});
    return True;
}

walker CollectClosureKids {
    has max_depth: int;
    has claimed: dict[int, bool] = {};
    has out: list[int] = [];

    can pivot with Category entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        clos: list = [here ->:Closure:->];
        for cl in clos {
            if cl.depth < self.max_depth {
                nbrs: list = [cl ->];
                for nb in nbrs {
                    self.out.append(nb.cid);
                }
            }
        }
        disengage;
    }
}

def closure_child_ids(parent_id: int, max_depth: int) -> list[int] {
    parent = find_category_by_cid(parent_id);
    if parent is None {
        return [];
    }
    w = parent spawn CollectClosureKids(max_depth=max_depth, claimed={}, out=[]);
    rows: list[int] = w.out;
    return sorted(rows);
}

def find_categories_by_ids(ids: list[int]) -> list[tuple[int, str]] {
    want: dict[int, bool] = {};
    for i in ids {
        want[i] = True;
    }
    found: list[tuple[int, str]] = [];
    nodes: list[Category] = [root -->][?:Category];
    for nd in nodes {
        if nd.cid in want {
            found.append((nd.cid, nd.name));
        }
    }
    return sorted(found);
}

walker DemoRun {
    has claimed: dict[int, bool] = {};

    can init with entry {
        add_category(1, "A");
        add_category(2, "B");
        link_parent_child(1, 2);
        ids: list[int] = closure_child_ids(1, 3);
        print(ids);
        disengage;
    }
}

with entry {
    root spawn DemoRun;
}
