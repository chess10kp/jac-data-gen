"""Comment depth-cap anchor walk — 1f916-ai/1f916#249."""

node Comment {
    has cid: str;
    has depth: int = 0;
    has text: str = "";
    has stored_parent_id: str = "";
    has intended_parent_id: str = "";
}

edge Parent {}

walker AnchorSeek {
    has start_cid: str;
    has max_depth: int;
    has claimed: dict[str, bool] = {};
    has found_cid: str = "";
    has found_depth: int = -1;

    can climb with Comment entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.cid == self.start_cid {
            if here.depth < self.max_depth {
                self.found_cid = here.cid;
                self.found_depth = here.depth;
                disengage;
            }
            ups: list[Comment] = [here <-:Parent:-][?:Comment];
            if ups {
                for u in ups {
                    visit :0: u;
                }
            } else {
                disengage;
            }
        } else {
            if here.depth < self.max_depth {
                self.found_cid = here.cid;
                self.found_depth = here.depth;
                disengage;
            }
            ups2: list[Comment] = [here <-:Parent:-][?:Comment];
            if ups2 {
                for u in ups2 {
                    visit :0: u;
                }
            } else {
                disengage;
            }
        }
    }
}

def lookup_comment(graph_root: Comment, cid: str) -> Comment | None {
    for nd in [graph_root -->][?:Comment] {
        if nd.cid == cid {
            return nd;
        }
    }
    return None;
}

def find_anchor(graph_root: Comment, parent_cid: str, max_depth: int) -> dict {
    if parent_cid == "" {
        return {"cid": "", "depth": -1};
    }
    start = lookup_comment(graph_root, parent_cid);
    if start is None {
        return {"cid": "", "depth": -1};
    }
    w = start spawn AnchorSeek(start_cid=parent_cid, max_depth=max_depth, claimed={});
    if w.found_cid != "" {
        return {"cid": w.found_cid, "depth": w.found_depth};
    }
    return {"cid": "", "depth": -1};
}

def is_abort_shape(stored_parent_id: str, intended_parent_id: str) -> bool {
    if stored_parent_id == "" and intended_parent_id != "" {
        return True;
    }
    return False;
}

def attach_comment(graph_root: Comment, cid: str, depth: int, stored_parent_id: str) -> Comment {
    nd = Comment(cid=cid, depth=depth, stored_parent_id=stored_parent_id);
    graph_root ++> nd;
    if stored_parent_id != "" {
        parent = lookup_comment(graph_root, stored_parent_id);
        if parent is not None {
            parent +>:Parent:+> nd;
        }
    }
    return nd;
}

def create_comment(graph_root: Comment, parent_cid: str, text: str, max_depth: int, next_id: str) -> dict {
    anchor = find_anchor(graph_root, parent_cid, max_depth);
    stored_parent_id: str = "";
    depth: int = 0;
    intended_parent_id: str = "";
    if anchor["cid"] != "" {
        stored_parent_id = anchor["cid"];
        depth = anchor["depth"] + 1;
        intended_parent_id = parent_cid;
    } else {
        stored_parent_id = "";
        depth = 0;
        intended_parent_id = parent_cid;
    }
    nd = Comment(
        cid=next_id,
        depth=depth,
        text=text,
        stored_parent_id=stored_parent_id,
        intended_parent_id=intended_parent_id
    );
    graph_root ++> nd;
    if stored_parent_id != "" {
        parent = lookup_comment(graph_root, stored_parent_id);
        if parent is not None {
            parent +>:Parent:+> nd;
        }
    }
    abort_shape = is_abort_shape(stored_parent_id, intended_parent_id);
    return {
        "cid": next_id,
        "depth": depth,
        "text": text,
        "stored_parent_id": stored_parent_id,
        "intended_parent_id": intended_parent_id,
        "abort_shape": abort_shape
    };
}

walker Demo {
    has graph_root: Comment;
    has max_depth: int = 3;

    can run with Comment entry {
        if here.cid != "__root__" {
            skip;
        }
        attach_comment(self.graph_root, "r0", 0, "");
        attach_comment(self.graph_root, "r1", 1, "r0");
        attach_comment(self.graph_root, "r2", 2, "r1");
        attach_comment(self.graph_root, "r3", 3, "r2");
        r = create_comment(self.graph_root, "r3", "reply", self.max_depth, "c1");
        print(
            r["cid"],
            r["stored_parent_id"],
            r["depth"],
            r["intended_parent_id"],
            r["abort_shape"]
        );
    }
}

with entry {
    graph_root = Comment(cid="__root__", depth=-1);
    root ++> graph_root;
    w = graph_root spawn Demo(graph_root=graph_root, max_depth=3);
}

test "find_anchor_empty_parent" {
    graph_root = Comment(cid="__root__", depth=-1);
    root ++> graph_root;
    a = find_anchor(graph_root, "", 3);
    assert (a["cid"] == "");
    assert (a["depth"] == -1);
}

test "find_anchor_unknown_parent" {
    graph_root = Comment(cid="__root__", depth=-1);
    root ++> graph_root;
    a = find_anchor(graph_root, "missing", 3);
    assert (a["cid"] == "");
    assert (a["depth"] == -1);
}

test "find_anchor_depth_cap_fallback" {
    graph_root = Comment(cid="__root__", depth=-1);
    root ++> graph_root;
    attach_comment(graph_root, "r0", 0, "");
    attach_comment(graph_root, "r1", 1, "r0");
    attach_comment(graph_root, "r2", 2, "r1");
    attach_comment(graph_root, "r3", 3, "r2");
    a = find_anchor(graph_root, "r3", 3);
    assert (a["cid"] == "r2");
    assert (a["depth"] == 2);
}

test "is_abort_shape_cases" {
    assert (is_abort_shape("", "r1") == True);
    assert (is_abort_shape("r0", "r1") == False);
    assert (is_abort_shape("", "") == False);
}

test "create_comment_depth_cap_stored_anchor" {
    graph_root = Comment(cid="__root__", depth=-1);
    root ++> graph_root;
    attach_comment(graph_root, "r0", 0, "");
    attach_comment(graph_root, "r1", 1, "r0");
    attach_comment(graph_root, "r2", 2, "r1");
    attach_comment(graph_root, "r3", 3, "r2");
    r = create_comment(graph_root, "r3", "reply", 3, "c1");
    assert (r["cid"] == "c1");
    assert (r["stored_parent_id"] == "r2");
    assert (r["depth"] == 3);
    assert (r["intended_parent_id"] == "r3");
    assert (r["abort_shape"] == False);
}

test "create_comment_no_anchor_abort_shape" {
    graph_root = Comment(cid="__root__", depth=-1);
    root ++> graph_root;
    r = create_comment(graph_root, "ghost", "orphan", 3, "c9");
    assert (r["stored_parent_id"] == "");
    assert (r["depth"] == 0);
    assert (r["intended_parent_id"] == "ghost");
    assert (r["abort_shape"] == True);
}
