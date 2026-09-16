# ronfeathers-LD/SOW-Generator#143
# getFolderStructure: unbounded sequential recursion (N+1 Drive calls).
# Idiomatic OSP lift: single bounded walker with claim-map memo instead of
# serial per-subfolder recursion; parent-name lookups memoized.

node Folder {
    has fid: str;
    has name: str;
}

edge Child {
    has page_token: str = "";
}

# memo of folder-id -> name, replaces the serial files.get per parent
def lookup_name(memo: dict[str, str], fid: str, folders: dict[str, Folder]) -> str {
    if fid in memo { return memo[fid]; }
    if fid in folders {
        memo[fid] = folders[fid].name;
        return memo[fid];
    }
    memo[fid] = "<unknown>";
    return "<unknown>";
}

walker FolderWalk {
    has max_depth: int = 3;
    has max_nodes: int = 1000;
    has seen: dict[str, bool] = {};
    has found: list[tuple[str, int, str]] = [];
    has budget: int = 1000;

    can step with Folder entry {
        # claim-map cycle policy: skip revisits, never disengage on revisit
        if here.fid in self.seen { skip; }
        self.seen[here.fid] = True;
        if self.budget <= 0 { disengage; }
        self.budget = self.budget - 1;
        self.found.append((here.fid, here.name, self.depth));
        kids: list[Folder] = [];
        for ch in [here ->:Child:->][?:Folder] {
            kids.append(ch);
        }
        # depth cap mirrors maxDepth=3 default; bounded fan-out replaces N+1
        if self.depth >= self.max_depth { disengage; }
        if len(kids) == 0 {
            visit [] else { disengage; }
        }
        for kid in kids {
            visit kid;
        }
    }
}

# public API shape matches getFolderStructure(root, maxDepth)
def folder_structure(root_node: Folder, max_depth: int = 3) -> list[tuple[str, int, str]] {
    w = root_node spawn FolderWalk(max_depth=max_depth, seen={});
    return w.found;
}

# public API matching getFolderContents(parentId) parent-name lookup
def folder_contents(fid: str, folders: dict[str, Folder], memo: dict[str, str]) -> tuple[str, list[str]] {
    nm = lookup_name(memo, fid, folders);
    kids: list[str] = [];
    if fid in folders {
        for ch in [folders[fid] ->:Child:->][?:Folder] {
            kids.append(ch.fid);
        }
    }
    kids = sorted(kids);
    return (nm, kids);
}

# hidden tests for iss_ronfeathers-LD__SOW-Generator__143
test "structure_walk_bounded" {
    a = Folder(fid="a", name="root");
    b = Folder(fid="b", name="child");
    c = Folder(fid="c", name="grand");
    a +>:Child:+> b;
    b +>:Child:+> c;
    res = folder_structure(a, 1);
    assert len(res) == 1;
    assert res[0][0] == "a";
    assert res[0][1] == 0;
    assert res[0][2] == "root";
}

test "structure_depth_three" {
    a = Folder(fid="a", name="r");
    b = Folder(fid="b", name="x");
    c = Folder(fid="c", name="y");
    d = Folder(fid="d", name="z");
    a +>:Child:+> b;
    b +>:Child:+> c;
    c +>:Child:+> d;
    res = folder_structure(a, 3);
    assert len(res) == 3;
}

test "cycle_no_infinite" {
    a = Folder(fid="a", name="r");
    b = Folder(fid="b", name="x");
    a +>:Child:+> b;
    b +>:Child:+> a;
    res = folder_structure(a, 5);
    ids: list[str] = [];
    for t in res { ids.append(t[0]); }
    assert len(ids) == 2;
    assert sorted(ids) == ["a", "b"];
}

test "diamond_order_independent" {
    a = Folder(fid="a", name="r");
    b = Folder(fid="b", name="x");
    c = Folder(fid="c", name="y");
    d = Folder(fid="d", name="shared");
    a +>:Child:+> b;
    a +>:Child:+> c;
    b +>:Child:+> d;
    c +>:Child:+> d;
    res1 = folder_structure(a, 3);
    res2 = folder_structure(a, 3);
    ids1: list[str] = [];
    ids2: list[str] = [];
    for t in res1 { ids1.append(t[0]); }
    for t in res2 { ids2.append(t[0]); }
    assert sorted(ids1) == sorted(ids2);
    assert len(ids1) == 4;
}

test "contents_and_memo" {
    a = Folder(fid="a", name="root");
    b = Folder(fid="b", name="kid1");
    c = Folder(fid="c", name="kid2");
    a +>:Child:+> b;
    a +>:Child:+> c;
    memo: dict[str, str] = {};
    r = folder_contents("a", {"a": a, "b": b, "c": c}, memo);
    assert r[0] == "root";
    assert r[1] == ["b", "c"];
    r2 = folder_contents("a", {"a": a, "b": b, "c": c}, memo);
    assert r2[0] == "root";
}

test "unknown_id_tolerance" {
    memo: dict[str, str] = {};
    r = folder_contents("zzz", {}, memo);
    assert r[0] == "<unknown>";
    assert r[1] == [];
}
