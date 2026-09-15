"""dbeaver/dbeaver#38286 — recursive subtree traversal (recursive-CTE lift)."""

node TreeNode {
    has cid: int;
    has parent_id: int = -1;
    has name: str;
}

edge ChildOf {}

walker FindWalker {
    has target_id: int = 0;
    has claimed: dict[str, bool] = {};
    has result: TreeNode | None = None;

    can seek with TreeNode entry {
        key = str(here.cid);
        if key in self.claimed { skip; }
        self.claimed[key] = True;
        if here.cid == self.target_id {
            self.result = here;
            print("found", here.cid);
            disengage;
        }
        kids: list[TreeNode] = [here ->:ChildOf:->][?:TreeNode];
        visit kids else { disengage; };
    }
}

walker SubtreeWalker {
    has anchor_id: int = 0;
    has claimed: dict[str, bool] = {};
    has depths: dict[str, int] = {};
    has found: list[dict] = [];

    can collect with TreeNode entry {
        key = str(here.cid);
        if key in self.claimed { skip; }
        self.claimed[key] = True;
        depth: int = 0;
        if key in self.depths {
            depth = self.depths[key];
        } elif here.cid == self.anchor_id {
            depth = 0;
        }
        row: dict = {};
        row["id"] = here.cid;
        row["parent_id"] = here.parent_id;
        row["name"] = here.name;
        row["depth"] = depth;
        self.found.append(row);
        print("subtree", here.cid, depth);
        kids: list[TreeNode] = [here ->:ChildOf:->][?:TreeNode];
        kid_cids: list[int] = [];
        for kid in kids {
            kid_cids.append(kid.cid);
        }
        kid_cids = sorted(kid_cids);
        visit_kids: list[TreeNode] = [];
        for cid in kid_cids {
            for kid in kids {
                if kid.cid == cid {
                    visit_kids.append(kid);
                }
            }
        }
        for kid in visit_kids {
            kid_key = str(kid.cid);
            self.depths[kid_key] = depth + 1;
        }
        visit visit_kids;
    }
}

def build_tree(rows: list[dict]) -> TreeNode {
    graph_root = TreeNode(cid=0, parent_id=-1, name="__root__");
    root ++> graph_root;
    index: dict[int, TreeNode] = {};
    for row in rows {
        rid: int = row["id"];
        pid: int = -1;
        if "parent_id" in row and row["parent_id"] is not None {
            pid = row["parent_id"];
        }
        nm: str = row["name"];
        nd = TreeNode(cid=rid, parent_id=pid, name=nm);
        graph_root ++> nd;
        index[rid] = nd;
    }
    for row in rows {
        rid: int = row["id"];
        pid: int = -1;
        if "parent_id" in row and row["parent_id"] is not None {
            pid = row["parent_id"];
        }
        if pid >= 0 and pid in index {
            index[pid] +>:ChildOf:+> index[rid];
        }
    }
    return graph_root;
}

def find_node(graph_root: TreeNode, node_id: int) -> TreeNode | None {
    tops: list[TreeNode] = [graph_root -->];
    for top in tops {
        if top.cid == node_id {
            return top;
        }
        fw = top spawn FindWalker(target_id=node_id);
        if fw.result is not None {
            return fw.result;
        }
    }
    return None;
}

def recursive_subtree_rows(graph_root: TreeNode, start_id: int) -> list[dict] {
    anchor = find_node(graph_root, start_id);
    if anchor is None {
        return [];
    }
    wk = anchor spawn SubtreeWalker(anchor_id=start_id);
    return wk.found;
}
