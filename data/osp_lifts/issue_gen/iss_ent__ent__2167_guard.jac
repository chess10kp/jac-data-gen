"""ent/ent#2167 - phased recursive undeleted traversal with separate ORDER/LIMIT."""

node file {
    has cid: str;
    has name: str;
    has deleted: bool = False;
}

edge child {}

obj fs_graph {
    has roots: list[file] = [];
    has by_cid: dict[str, file] = {};
}

obj traverse_state {
    has claimed: dict[str, bool] = {};
    has names: list[str] = [];
}

walker anchor_touch {
    has st: traverse_state;
    has picked: list[file] = [];

    can touch with file entry {
        if here.cid in self.st.claimed {
            skip;
        }
        self.st.claimed[here.cid] = True;
        self.st.names.append(here.name);
        self.picked.append(here);
        print(here.name);
    }
}

walker expand_touch {
    has st: traverse_state;
    has order_key: str = "name";
    has row_limit: int | None = None;
    has picked: list[file] = [];

    can touch with file entry {
        kids: list[file] = [here ->:child:->][?:file];
        cands: list[file] = [];
        for k in kids {
            if not k.deleted and k.cid not in self.st.claimed {
                cands.append(k);
            }
        }
        cands = sort_by_key(cands, self.order_key);
        cands = take_limit(cands, self.row_limit);
        for k in cands {
            self.st.claimed[k.cid] = True;
            self.st.names.append(k.name);
            self.picked.append(k);
            print(k.name);
        }
    }
}

walker dfs_probe {
    has claimed: dict[str, bool] = {};
    has cids: list[str] = [];

    can step with file entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.cids.append(here.cid);
        print(here.cid);
        kids: list[file] = [here ->:child:->][?:file];
        visit :0: kids;
    }
}

def key_val(f: file, key: str) -> str {
    if key == "id" {
        return f.cid;
    }
    return f.name;
}

def sort_by_key(items: list[file], key: str) -> list[file] {
    xs: list[file] = [];
    for it in items {
        xs.append(it);
    }
    n = len(xs);
    i = 0;
    while i < n {
        j = i + 1;
        while j < n {
            ki = key_val(xs[i], key);
            kj = key_val(xs[j], key);
            if kj < ki {
                tmp = xs[i];
                xs[i] = xs[j];
                xs[j] = tmp;
            }
            j += 1;
        }
        i += 1;
    }
    return xs;
}

def take_limit(items: list[file], lim: int | None) -> list[file] {
    if lim is None {
        return items;
    }
    out: list[file] = [];
    i = 0;
    for it in items {
        if i >= lim {
            break;
        }
        out.append(it);
        i += 1;
    }
    return out;
}

def register(g: fs_graph, f: file) {
    g.by_cid[f.cid] = f;
}

def make_graph -> fs_graph {
    g = fs_graph();
    a = file(cid="a", name="a");
    root ++> a;
    g.roots.append(a);
    register(g, a);
    b = file(cid="b", name="b");
    a +>:child:+> b;
    register(g, b);
    ba = file(cid="ba", name="ba");
    b +>:child:+> ba;
    register(g, ba);
    bb = file(cid="bb", name="bb");
    b +>:child:+> bb;
    register(g, bb);
    bc = file(cid="bc", name="bc", deleted=True);
    b +>:child:+> bc;
    register(g, bc);
    c = file(cid="c", name="c", deleted=True);
    a +>:child:+> c;
    register(g, c);
    ca = file(cid="ca", name="ca");
    c +>:child:+> ca;
    register(g, ca);
    cb = file(cid="cb", name="cb");
    c +>:child:+> cb;
    register(g, cb);
    d = file(cid="d", name="d", deleted=True);
    a +>:child:+> d;
    register(g, d);
    return g;
}

def make_diamond_graph -> fs_graph {
    g = fs_graph();
    r = file(cid="r", name="r");
    root ++> r;
    g.roots.append(r);
    register(g, r);
    x = file(cid="x", name="x");
    r +>:child:+> x;
    register(g, x);
    y = file(cid="y", name="y");
    r +>:child:+> y;
    register(g, y);
    z = file(cid="z", name="z");
    x +>:child:+> z;
    y +>:child:+> z;
    register(g, z);
    return g;
}

def make_two_root_graph -> fs_graph {
    g = fs_graph();
    a = file(cid="a", name="a");
    root ++> a;
    g.roots.append(a);
    register(g, a);
    m = file(cid="m", name="m");
    root ++> m;
    g.roots.append(m);
    register(g, m);
    return g;
}

def recursive_undeleted_names(
    g: fs_graph,
    initial_order: str = "name",
    initial_limit: int | None = None,
    recursive_order: str = "name",
    recursive_limit: int | None = None,
) -> list[str] {
    st = traverse_state();
    anchor: list[file] = [];
    for r in g.roots {
        if not r.deleted {
            anchor.append(r);
        }
    }
    anchor = sort_by_key(anchor, initial_order);
    anchor = take_limit(anchor, initial_limit);
    frontier: list[file] = [];
    for seed in anchor {
        w = seed spawn anchor_touch(st=st);
        for p in w.picked {
            frontier.append(p);
        }
    }
    while len(frontier) > 0 {
        next_f: list[file] = [];
        for p in frontier {
            w = p spawn expand_touch(
                st=st,
                order_key=recursive_order,
                row_limit=recursive_limit,
            );
            for pf in w.picked {
                next_f.append(pf);
            }
        }
        frontier = next_f;
    }
    return st.names;
}

def file_name_for(g: fs_graph, cid: str) -> str | None {
    if cid in g.by_cid {
        return g.by_cid[cid].name;
    }
    return None;
}

def walk_probe_cids(g: fs_graph) -> list[str] {
    if len(g.roots) == 0 {
        return [];
    }
    start = g.roots[0];
    w = start spawn dfs_probe(claimed={});
    return w.cids;
}

test "undeleted_default" {
    g = make_graph();
    got = recursive_undeleted_names(g);
    assert got == ["a", "b", "ba", "bb"];
}

test "initial_limit_two_roots" {
    g = make_two_root_graph();
    got = recursive_undeleted_names(g, initial_limit=1);
    assert got == ["a"];
}

test "recursive_limit_one" {
    g = make_graph();
    got = recursive_undeleted_names(g, recursive_limit=1);
    assert got == ["a", "b", "ba"];
}

test "file_name_lookup" {
    g = make_graph();
    assert file_name_for(g, "ba") == "ba";
    assert file_name_for(g, "missing") is None;
}

test "walk_probe_diamond" {
    g = make_diamond_graph();
    got = walk_probe_cids(g);
    assert got == ["r", "y", "z", "x"];
}

test "initial_order_by_id" {
    g = make_two_root_graph();
    got = recursive_undeleted_names(g, initial_order="id", initial_limit=1);
    assert got == ["a"];
}
