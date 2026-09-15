"""casehubio/casehub-pages#369 — Workspace centre as root Container."""

node GraphHub {}

node Container {
    has cid: str;
    has layout: str = "free";
}

node Frame {
    has fid: str;
    has title: str = "";
}

edge Holds {}

walker FindContainer {
    has target: str;
    has found: Container | None = None;
    has claimed: dict[str, bool] = {};

    can start with GraphHub entry {
        print("find hub");
        tops: list = [here ->:Holds:->][?:Container];
        for nd in tops {
            visit :0: [nd];
        }
    }

    can scan with Container entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("find " + here.cid);
        if here.cid == self.target {
            self.found = here;
            disengage;
        }
        kids: list = [here ->:Holds:->][?:Container];
        for ch in kids {
            visit :0: [ch];
        }
    }
}

walker CollectFrames {
    has out: list[str] = [];
    has claimed: dict[str, bool] = {};

    can begin with Container entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("collect " + here.cid);
        frs: list = [here ->:Holds:->][?:Frame];
        for fr in frs {
            self.out.append(fr.fid);
        }
        subs: list = [here ->:Holds:->][?:Container];
        for sub in subs {
            visit :0: [sub];
        }
    }
}

def _graph_hub() -> GraphHub {
    hits: list = [root -->][?:GraphHub];
    if len(hits) > 0 {
        return hits[0];
    }
    h = GraphHub();
    root ++> h;
    return h;
}

def _find_container(target: str) -> Container | None {
    hub = _graph_hub();
    w = hub spawn FindContainer(target=target, found=None, claimed={});
    return w.found;
}

def make_workspace_root(layout: str = "free") -> str {
    hub = _graph_hub();
    n: int = len([hub ->:Holds:->][?:Container]);
    cid: str = "ws_" + str(n);
    ctr = Container(cid=cid, layout=layout);
    hub +>:Holds:+> ctr;
    return cid;
}

def add_child_container(parent_id: str, child_id: str, layout: str = "free") -> bool {
    par = _find_container(parent_id);
    if par is None {
        return False;
    }
    if _find_container(child_id) is not None {
        return False;
    }
    ch = Container(cid=child_id, layout=layout);
    par +>:Holds:+> ch;
    return True;
}

def attach_container(parent_id: str, child_id: str) -> bool {
    par = _find_container(parent_id);
    ch = _find_container(child_id);
    if par is None or ch is None {
        return False;
    }
    par +>:Holds:+> ch;
    return True;
}

def add_frame_entry(container_id: str, frame_id: str, title: str) -> bool {
    ctr = _find_container(container_id);
    if ctr is None {
        return False;
    }
    fr = Frame(fid=frame_id, title=title);
    ctr +>:Holds:+> fr;
    return True;
}

def set_layout(container_id: str, layout: str) -> bool {
    ctr = _find_container(container_id);
    if ctr is None {
        return False;
    }
    ctr.layout = layout;
    return True;
}

def get_layout(container_id: str) -> str | None {
    ctr = _find_container(container_id);
    if ctr is None {
        return None;
    }
    return ctr.layout;
}

def collect_frame_ids(root_id: str) -> list[str] {
    ctr = _find_container(root_id);
    if ctr is None {
        empty: list[str] = [];
        return empty;
    }
    w = ctr spawn CollectFrames(out=[], claimed={});
    return w.out;
}
