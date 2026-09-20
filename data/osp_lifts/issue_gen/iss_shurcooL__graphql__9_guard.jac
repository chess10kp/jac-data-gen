"""Synthetic before-code target: shurcooL/graphql#9."""

glob SCALAR_SET = ["Boolean", "Float", "ID", "Int", "String"];

node GType {
    has tname: str;
}

node Field {
    has fname: str;
    has ftype: str;
}

edge Owns {}
edge Refs {}

def is_scalar_type(ftype: str) -> bool {
    for s in SCALAR_SET {
        if ftype == s {
            return True;
        }
    }
    return False;
}

def sort_fields(items: list[Field]) -> list[Field] {
    out: list[Field] = list(items);
    n = len(out);
    i = 0;
    while i < n {
        j = 0;
        while j + 1 < n {
            if out[j].fname > out[j + 1].fname {
                tmp = out[j];
                out[j] = out[j + 1];
                out[j + 1] = tmp;
            }
            j += 1;
        }
        i += 1;
    }
    return out;
}

def make_schema(type_fields: dict[str, list[tuple[str, str]]]) -> dict {
    idx: dict[str, GType] = {};
    graph_root = GType(tname="__root__");
    root ++> graph_root;
    for tname in sorted(type_fields.keys()) {
        gt = GType(tname=tname);
        graph_root ++> gt;
        idx[tname] = gt;
    }
    for tname in sorted(type_fields.keys()) {
        gt = idx[tname];
        pairs = type_fields[tname];
        for pair in pairs {
            fname = pair[0];
            ftype = pair[1];
            fd = Field(fname=fname, ftype=ftype);
            gt +>:Owns:+> fd;
            if not is_scalar_type(ftype) {
                if ftype in idx {
                    tgt = idx[ftype];
                    fd +>:Refs:+> tgt;
                }
            }
        }
    }
    store: dict = {};
    store["root"] = graph_root;
    store["index"] = idx;
    return store;
}

walker RenderWalker {
    has claimed: dict[str, bool] = {};
    has depth: int = 0;
    has max_depth: int = 1;
    has buf: list[str] = [];

    can render with GType entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if self.depth > self.max_depth {
            disengage;
        }
        fields: list[Field] = [];
        for fd in [here ->:Owns:->][?:Field] {
            fields.append(fd);
        }
        fields = sort_fields(fields);
        for fd in fields {
            if is_scalar_type(fd.ftype) {
                self.buf.append(fd.fname);
            } elif self.depth < self.max_depth {
                targets: list[GType] = [];
                for tg in [fd ->:Refs:->][?:GType] {
                    targets.append(tg);
                }
                if len(targets) > 0 {
                    sub = targets[0] spawn RenderWalker(
                        claimed={},
                        depth=self.depth + 1,
                        max_depth=self.max_depth,
                        buf=[]
                    );
                    inner = " ".join(sub.buf);
                    if inner != "" {
                        piece = fd.fname + " { " + inner + " }";
                        self.buf.append(piece);
                    }
                }
            }
        }
        print("render " + here.tname + " d=" + str(self.depth));
    }
}

walker PathWalker {
    has claimed: dict[str, bool] = {};
    has depth: int = 0;
    has max_depth: int = 1;
    has prefix: str = "";
    has paths: list[str] = [];

    can collect with GType entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if self.depth > self.max_depth {
            disengage;
        }
        fields: list[Field] = [];
        for fd in [here ->:Owns:->][?:Field] {
            fields.append(fd);
        }
        fields = sort_fields(fields);
        for fd in fields {
            path = fd.fname;
            if self.prefix != "" {
                path = self.prefix + "." + fd.fname;
            }
            if is_scalar_type(fd.ftype) {
                self.paths.append(path);
            } elif self.depth < self.max_depth {
                targets: list[GType] = [];
                for tg in [fd ->:Refs:->][?:GType] {
                    targets.append(tg);
                }
                if len(targets) > 0 {
                    sub = targets[0] spawn PathWalker(
                        claimed={},
                        depth=self.depth + 1,
                        max_depth=self.max_depth,
                        prefix=path,
                        paths=[]
                    );
                    for p in sub.paths {
                        self.paths.append(p);
                    }
                }
            }
        }
        print("paths " + here.tname + " d=" + str(self.depth));
    }
}

def write_query(store: dict[str, any], root_type: str, max_depth: int = 1) -> str {
    if max_depth < 0 {
        max_depth = 0;
    }
    idx = store["index"] as dict[str, GType];
    if root_type not in idx {
        return "{ }";
    }
    gt = idx[root_type];
    w = gt spawn RenderWalker(claimed={}, depth=0, max_depth=max_depth, buf=[]);
    inner = " ".join(w.buf);
    return "{ " + inner + " }";
}

def selection_paths(store: dict[str, any], root_type: str, max_depth: int = 1) -> list[str] {
    if max_depth < 0 {
        max_depth = 0;
    }
    idx = store["index"] as dict[str, GType];
    if root_type not in idx {
        return [];
    }
    gt = idx[root_type];
    w = gt spawn PathWalker(claimed={}, depth=0, max_depth=max_depth, prefix="", paths=[]);
    return sorted(w.paths);
}

def type_known(store: dict[str, any], type_name: str) -> bool {
    idx = store["index"] as dict[str, GType];
    return type_name in idx;
}

test "write_query_scalar_fields" {
    tf: dict[str, list[tuple[str, str]]] = {};
    tf["Query"] = [("id", "ID"), ("title", "String")];
    store = make_schema(tf);
    assert write_query(store, "Query", 1) == "{ id title }";
}

test "write_query_unknown_root" {
    tf: dict[str, list[tuple[str, str]]] = {};
    tf["Query"] = [("id", "ID")];
    store = make_schema(tf);
    assert write_query(store, "Missing", 1) == "{ }";
}

test "selection_paths_depth_two" {
    tf: dict[str, list[tuple[str, str]]] = {};
    tf["Query"] = [("user", "User")];
    tf["User"] = [("name", "String"), ("posts", "Post")];
    tf["Post"] = [("title", "String")];
    store = make_schema(tf);
    got = selection_paths(store, "Query", 2);
    want: list[str] = ["user.name", "user.posts.title"];
    assert got == want;
}

test "write_query_depth_one" {
    tf: dict[str, list[tuple[str, str]]] = {};
    tf["Query"] = [("user", "User")];
    tf["User"] = [("name", "String"), ("posts", "Post")];
    tf["Post"] = [("title", "String")];
    store = make_schema(tf);
    assert write_query(store, "Query", 1) == "{ user { name } }";
}

test "type_known" {
    tf: dict[str, list[tuple[str, str]]] = {};
    tf["Query"] = [("id", "ID")];
    store = make_schema(tf);
    assert type_known(store, "Query") == True;
    assert type_known(store, "Ghost") == False;
}

test "max_depth_negative_clamps" {
    tf: dict[str, list[tuple[str, str]]] = {};
    tf["Query"] = [("user", "User"), ("id", "ID")];
    tf["User"] = [("name", "String")];
    store = make_schema(tf);
    assert write_query(store, "Query", -1) == "{ id user }";
}
