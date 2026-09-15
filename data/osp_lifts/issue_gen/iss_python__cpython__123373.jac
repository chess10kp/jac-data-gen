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
