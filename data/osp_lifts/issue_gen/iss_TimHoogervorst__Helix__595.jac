node Source {
    has sid: str;
    has kind: str;
    has status: str = "active";
    has source_id: str = "";
    has source_kind: str = "";
    has source_path: list[str] = [];
}

edge SourceLink {}

walker ChildrenWalker {
    has recursive: bool = False;
    has include_start: bool = False;
    has claimed: dict[str, bool] = {};
    has found: list[Source] = [];

    can step with Source entry {
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        print("children " + here.sid);

        if self.include_start {
            self.found.append(here);
        } else {
            self.include_start = True;
        }

        if self.recursive {
            for kid in [here ->:SourceLink:->][?:Source] {
                visit :0: [kid];
            }
        }
    }
}

walker LookupWalker {
    has target: str;
    has claimed: dict[str, bool] = {};
    has found: Source | None = None;

    can step with Source entry {
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        print("lookup " + here.sid);

        if here.sid == self.target {
            self.found = here;
        }

        for kid in [here ->:SourceLink:->][?:Source] {
            visit :0: [kid];
        }
    }
}

walker PathWalker {
    has claimed: dict[str, bool] = {};

    can step with Source entry {
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        print("path " + here.sid);

        for kid in [here ->:SourceLink:->][?:Source] {
            kid.source_path = here.source_path + [
                here.kind + ":" + here.sid
            ];
            visit :0: [kid];
        }
    }
}

walker StatusWalker {
    has next_status: str;
    has claimed: dict[str, bool] = {};
    has changed: list[str] = [];

    can step with Source entry {
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        here.status = self.next_status;
        self.changed.append(here.sid);
        print("status " + here.sid);

        for kid in [here ->:SourceLink:->][?:Source] {
            visit :0: [kid];
        }
    }
}

def make_source(sid: str, kind: str) -> Source {
    source = Source(sid=sid, kind=kind);
    return source;
}

def set_source(parent: Source, child: Source) -> None {
    if child.kind != "project" and parent.sid != child.sid {
        child.source_id = parent.sid;
        child.source_kind = parent.kind;
        child.source_path = parent.source_path + [
            parent.kind + ":" + parent.sid
        ];
        parent +>:SourceLink:+> child;
        wk = child spawn PathWalker(claimed={});
    }
}

def children_of(source: Source, recursive: bool = False) -> list[Source] {
    wk = source spawn ChildrenWalker(
        recursive=recursive,
        claimed={}
    );
    return wk.found;
}

def find_source(graph_root: Source, sid: str) -> Source | None {
    wk = graph_root spawn LookupWalker(target=sid, claimed={});
    return wk.found;
}

def source_path_of(source: Source) -> list[str] {
    return source.source_path;
}

def cascade_status(source: Source, next_status: str) -> list[str] {
    wk = source spawn StatusWalker(
        next_status=next_status,
        claimed={}
    );
    return wk.changed;
}

def delete_source_tree(source: Source) -> list[str] {
    descendants = children_of(source, True);
    deleted: list[str] = [];

    for item in descendants {
        deleted.append(item.sid);
        destroy item;
    }
    deleted.append(source.sid);
    destroy source;
    return deleted;
}
