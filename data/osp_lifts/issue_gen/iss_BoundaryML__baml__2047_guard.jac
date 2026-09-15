"""BoundaryML/baml#2047 - recursive schema type graph resolution."""

node TypeNode {
    has name: str;
    has kind: str;
}

node FieldSlot {
    has label: str;
}

edge HasField {}
edge Refs {}

obj SchemaHandle {
    has anchor: TypeNode;
}

def link_field(parent: TypeNode, label: str, child: TypeNode) -> FieldSlot {
    sl = FieldSlot(label=label);
    parent +>:HasField:+> sl;
    sl +>:Refs:+> child;
    return sl;
}

def make_schema() -> SchemaHandle {
    bs = TypeNode(name="BalanceSheet", kind="structured");
    fy = TypeNode(name="FinancialYear", kind="structured");
    assets = TypeNode(name="Assets", kind="structured");
    liabilities = TypeNode(name="Liabilities", kind="structured");
    equity = TypeNode(name="Equity", kind="structured");
    meta = TypeNode(name="DocumentMeta", kind="meta");
    root ++> bs;
    link_field(bs, "years", fy);
    link_field(fy, "assets", assets);
    link_field(fy, "alt_assets", assets);
    link_field(fy, "liabilities", liabilities);
    link_field(fy, "equity", equity);
    link_field(equity, "meta", meta);
    link_field(meta, "sheet", bs);
    return SchemaHandle(anchor=bs);
}

walker FindStart {
    has target: str;
    has hit: TypeNode | None = None;
    has claimed: dict[str, bool] = {};

    can seek with TypeNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name == self.target {
            self.hit = here;
            disengage;
        }
        kids: list[TypeNode] = [];
        for sl in [here ->:HasField:->][?:FieldSlot] {
            for rn in [sl ->:Refs:->][?:TypeNode] {
                kids.append(rn);
            }
        }
        visit :0: kids else { disengage; }
    }
}

walker TypeWalk {
    has claimed: dict[str, bool] = {};
    has names: list[str] = [];

    can step with TypeNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.names.append(here.name);
        print(here.name);
        kids: list[TypeNode] = [];
        for sl in [here ->:HasField:->][?:FieldSlot] {
            for rn in [sl ->:Refs:->][?:TypeNode] {
                kids.append(rn);
            }
        }
        visit :0: kids else { disengage; }
    }
}

walker PathWalk {
    has claimed: dict[str, bool] = {};
    has paths: list[str] = [];
    has prefix: str = "";

    can walk with TypeNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        kids: list[TypeNode] = [];
        for sl in [here ->:HasField:->][?:FieldSlot] {
            nxt: str = sl.label;
            if self.prefix != "" {
                nxt = self.prefix + "." + sl.label;
            }
            self.paths.append(nxt);
            print(nxt);
            for rn in [sl ->:Refs:->][?:TypeNode] {
                kids.append(rn);
            }
        }
        visit :0: kids else { disengage; }
    }
}

def walk_type_names(handle: SchemaHandle, start: str) -> list[str] {
    finder = handle.anchor spawn FindStart(target=start, claimed={}, hit=None);
    if finder.hit is None {
        return [];
    }
    tw = finder.hit spawn TypeWalk(claimed={}, names=[]);
    return sorted(tw.names);
}

def field_paths(handle: SchemaHandle, start: str) -> list[str] {
    finder = handle.anchor spawn FindStart(target=start, claimed={}, hit=None);
    if finder.hit is None {
        return [];
    }
    pw = finder.hit spawn PathWalk(claimed={}, paths=[], prefix="");
    return sorted(pw.paths);
}

def streaming_vs_final(streaming: list[str], final: list[str]) -> bool {
    if len(streaming) == 0 {
        return False;
    }
    present: dict[str, bool] = {};
    for x in final {
        present[x] = True;
    }
    for s in streaming {
        if s not in present {
            return True;
        }
    }
    return False;
}

walker DemoWalk {
    has claimed: dict[str, bool] = {};

    can demo with TypeNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        print(here.name);
        kids: list[TypeNode] = [];
        for sl in [here ->:HasField:->][?:FieldSlot] {
            for rn in [sl ->:Refs:->][?:TypeNode] {
                kids.append(rn);
            }
        }
        visit :0: kids else { disengage; }
    }
}

with entry {
    h = make_schema();
    root spawn DemoWalk(claimed={});
}

test "walk_type_names_balance_sheet" {
    h = make_schema();
    names = walk_type_names(h, "BalanceSheet");
    assert names == ["Assets", "BalanceSheet", "DocumentMeta", "Equity", "FinancialYear", "Liabilities"];
}

test "walk_type_names_financial_year" {
    h = make_schema();
    names = walk_type_names(h, "FinancialYear");
    assert names == ["Assets", "DocumentMeta", "Equity", "FinancialYear", "Liabilities"];
}

test "walk_type_names_missing" {
    h = make_schema();
    assert walk_type_names(h, "NoSuchType") == [];
}

test "field_paths_balance_sheet" {
    h = make_schema();
    paths = field_paths(h, "BalanceSheet");
    assert paths == ["alt_assets", "assets", "equity", "liabilities", "meta", "sheet", "years"];
}

test "streaming_vs_final_detects_gap" {
    assert streaming_vs_final(["partial"], ["final"]) == True;
}

test "streaming_vs_final_subset_ok" {
    assert streaming_vs_final(["a"], ["a", "b"]) == False;
    assert streaming_vs_final([], ["a"]) == False;
}
