"""Idiomatic OSP lift for prisma/orm#4562: Tree structures support."""

node Category {
    has cid: int;
    has name: str;
}

edge ParentChild {}

obj TreeIndex {
    has roots: list[Category] = [];
}

walker TreeWalker {
    has target_id: int;
    has mode: str;
    has include_self: bool = False;
    has claimed: dict[int, bool] = {};
    has ids: list[int] = [];
    has found: Category | None = None;

    can walk with Category entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);

        if self.mode == "find" {
            if here.cid == self.target_id {
                self.found = here;
                disengage;
            }
            for kid in [here ->:ParentChild:->][?:Category] {
                visit :0: [kid];
            }
        } else {
            if self.mode == "down" {
                if here.cid == self.target_id {
                    if self.include_self { self.ids.append(here.cid); }
                } else {
                    self.ids.append(here.cid);
                }
                for kid in [here ->:ParentChild:->][?:Category] {
                    visit :0: [kid];
                }
            } else {
                if here.cid == self.target_id {
                    if self.include_self { self.ids.append(here.cid); }
                } else {
                    self.ids.append(here.cid);
                }
                for parent in [here <-:ParentChild:<-][?:Category] {
                    visit :0: [parent];
                }
            }
        }
    }
}

def _locate(tree: TreeIndex, node_id: int) -> Category | None {
    target: Category | None = None;
    for root_node in tree.roots {
        if target == None {
            w = root_node spawn TreeWalker(
                target_id=node_id, mode="find", claimed={}
            );
            if w.found != None { target = w.found; }
        }
    }
    return target;
}

def get_descendants(
    tree: TreeIndex, node_id: int, include_self: bool = False
) -> list[int] {
    target = _locate(tree, node_id);
    if target == None { return []; }
    w = target spawn TreeWalker(
        target_id=node_id, mode="down",
        include_self=include_self, claimed={}
    );
    return sorted(w.ids);
}

def get_ancestors(
    tree: TreeIndex, node_id: int, include_self: bool = False
) -> list[int] {
    target = _locate(tree, node_id);
    if target == None { return []; }
    w = target spawn TreeWalker(
        target_id=node_id, mode="up",
        include_self=include_self, claimed={}
    );
    return sorted(w.ids);
}

def get_children(tree: TreeIndex, node_id: int) -> list[int] {
    target = _locate(tree, node_id);
    if target == None { return []; }
    kids: list[int] = [];
    for kid in [target ->:ParentChild:->][?:Category] {
        kids.append(kid.cid);
    }
    return sorted(kids);
}

def get_roots(tree: TreeIndex) -> list[int] {
    ids: list[int] = [];
    for root_node in tree.roots {
        ids.append(root_node.cid);
        print(root_node.cid);
    }
    return sorted(ids);
}
