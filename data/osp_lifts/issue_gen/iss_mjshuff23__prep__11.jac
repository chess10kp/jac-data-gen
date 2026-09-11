"""mjshuff23/prep#11 — Structure-pack dependency graph (Wave C graph pack)."""

obj PackGraph {
    def add_pack(pack_id: str) -> None;
    def link(parent: str, child: str) -> None;
    def descendants(pack_id: str) -> list[str];
}

node Pack {
    has pack_id: str;
}

edge Contains {}

walker PackClosureWalker {
    has origin: str;
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can start with Root entry {
        matches = [root-->][?:Pack, pack_id == self.origin];
        if matches {
            visit [matches[0]];
        } else {
            disengage;
        }
    }

    can step with Pack entry {
        if here.pack_id in self.claimed {
            skip;
        }
        self.claimed[here.pack_id] = True;
        if here.pack_id != self.origin {
            self.hits.append(here.pack_id);
        }
        visit [->:Contains:->];
    }
}

impl PackGraph.add_pack(pack_id: str) -> None {
    target = pack_id;
    if not [root-->][?:Pack, pack_id == target] {
        root ++> Pack(pack_id=pack_id);
    }
}

impl PackGraph.link(parent: str, child: str) -> None {
    par_list = [root-->][?:Pack, pack_id == parent];
    if par_list {
        par = par_list[0];
    } else {
        par = root ++> Pack(pack_id=parent);
    }
    child_list = [root-->][?:Pack, pack_id == child];
    if child_list {
        ch = child_list[0];
    } else {
        ch = root ++> Pack(pack_id=child);
    }
    par +>:Contains:+> ch;
}

impl PackGraph.descendants(pack_id: str) -> list[str] {
    target = pack_id;
    if not [root-->][?:Pack, pack_id == target] {
        return [];
    }
    w = root spawn PackClosureWalker(origin=pack_id);
    return sorted(w.hits);
}
