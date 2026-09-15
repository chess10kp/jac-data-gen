"""AST descendant traversal — BFS vs DFS. Ground truth: python/cpython#123373."""

node AstNode {
    has kind: str;
    has nid: str;
}

edge Child {}

walker BfsWalk {
    has claimed: dict[str, bool] = {};
    has order: list[AstNode] = [];
    can step with AstNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.order.append(here);
        print here.nid;
        kids: list[AstNode] = [];
        for ch in [here ->:Child:->][?:AstNode] {
            kids.append(ch);
        }
        for kid in kids {
            visit kid;
        }
    }
}

walker DfsWalk {
    has claimed: dict[str, bool] = {};
    has order: list[AstNode] = [];
    can descend with AstNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.order.append(here);
        print here.nid;
        kids: list[AstNode] = [];
        for ch in [here ->:Child:->][?:AstNode] {
            kids.append(ch);
        }
        visit :0: kids;
    }
}

walker DemoWalker {
    can run with entry {
        mod = AstNode(kind="Module", nid="mod");
        root ++> mod;
        e1 = AstNode(kind="Expr", nid="e1");
        root ++> e1;
        e2 = AstNode(kind="If", nid="e2");
        root ++> e2;
        mod +>:Child:+> e1;
        mod +>:Child:+> e2;
        bfs = walk(mod);
        dfs = dfs_walk(mod);
        print {"bfs_len": len(bfs), "dfs_len": len(dfs)};
    }
}

def iter_child_nodes(ast_node: AstNode) -> list[AstNode] {
    kids: list[AstNode] = [];
    for ch in [ast_node ->:Child:->][?:AstNode] {
        kids.append(ch);
    }
    return kids;
}

def walk(node: AstNode) -> list[AstNode] {
    w = node spawn BfsWalk(claimed={}, order=[]);
    return w.order;
}

def dfs_walk(node: AstNode) -> list[AstNode] {
    w = node spawn DfsWalk(claimed={}, order=[]);
    return w.order;
}

def nids_of(nodes: list[AstNode]) -> list[str] {
    out: list[str] = [];
    for nd in nodes {
        out.append(nd.nid);
    }
    return out;
}

with entry {
    root spawn DemoWalker;
}

test "iter_child_nodes_returns_children" {
    mod = AstNode(kind="Module", nid="mod");
    e1 = AstNode(kind="Expr", nid="e1");
    e2 = AstNode(kind="If", nid="e2");
    root ++> mod;
    root ++> e1;
    root ++> e2;
    mod +>:Child:+> e1;
    mod +>:Child:+> e2;
    got = nids_of(iter_child_nodes(mod));
    assert sorted(got) == ["e1", "e2"];
}

test "walk_bfs_preorder" {
    mod = AstNode(kind="Module", nid="mod");
    e1 = AstNode(kind="Expr", nid="e1");
    e2 = AstNode(kind="If", nid="e2");
    root ++> mod;
    root ++> e1;
    root ++> e2;
    mod +>:Child:+> e1;
    mod +>:Child:+> e2;
    assert nids_of(walk(mod)) == ["mod", "e1", "e2"];
}

test "dfs_walk_preorder" {
    mod = AstNode(kind="Module", nid="mod");
    e1 = AstNode(kind="Expr", nid="e1");
    e2 = AstNode(kind="If", nid="e2");
    root ++> mod;
    root ++> e1;
    root ++> e2;
    mod +>:Child:+> e1;
    mod +>:Child:+> e2;
    assert nids_of(dfs_walk(mod)) == ["mod", "e2", "e1"];
}

test "walk_skips_revisit_diamond" {
    r = AstNode(kind="R", nid="r");
    a = AstNode(kind="A", nid="a");
    b = AstNode(kind="B", nid="b");
    c = AstNode(kind="C", nid="c");
    root ++> r;
    root ++> a;
    root ++> b;
    root ++> c;
    r +>:Child:+> a;
    r +>:Child:+> b;
    a +>:Child:+> c;
    b +>:Child:+> c;
    assert nids_of(walk(r)) == ["r", "a", "b", "c"];
}

test "walk_leaf_only_self" {
    leaf = AstNode(kind="Expr", nid="leaf");
    root ++> leaf;
    assert nids_of(walk(leaf)) == ["leaf"];
}

test "nids_of_preserves_order" {
    a = AstNode(kind="A", nid="a");
    b = AstNode(kind="B", nid="b");
    assert nids_of([a, b]) == ["a", "b"];
}
