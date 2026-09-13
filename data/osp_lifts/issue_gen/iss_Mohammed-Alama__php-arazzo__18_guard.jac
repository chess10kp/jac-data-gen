node ArazzoFile { has path: str; has kind: str = "workflow"; }
node Workspace { has name: str; }
node RawDocument { has path: str; has content: str = ""; }
node ArazzoDocument { has path: str; has parsed: bool = True; }
node FileParseCycleException { has message: str; has cycle_path: str; }
edge DependsOn {}
edge Holds {}
walker FileTraverseWalker {
    has claimed: dict[str, bool] = {};
    can step_file with ArazzoFile entry {
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        print("traverse " + here.path);
        deps: list[ArazzoFile] = [here ->:DependsOn:->][?:ArazzoFile];
        visit :0: deps else { disengage; }
    }
    can step_ws with Workspace entry {
        print("enter workspace " + here.name);
        kids: list[ArazzoFile] = [here ->:Holds:->][?:ArazzoFile];
        visit :0: kids else { disengage; }
    }
}
def create_workspace(name: str) -> Workspace {
    ws = Workspace(name=name);
    root +>:Holds:+> ws;
    return ws;
}
def add_file(ws: Workspace, path: str, kind: str) -> ArazzoFile {
    nd = ArazzoFile(path=path, kind=kind);
    ws +>:Holds:+> nd;
    return nd;
}
def add_file_dependency(src: ArazzoFile, dep: ArazzoFile) {
    src +>:DependsOn:+> dep;
}
def add_schema_reference(workflow_file: ArazzoFile, schema_file: ArazzoFile) {
    workflow_file +>:DependsOn:+> schema_file;
}
def add_source_description_ref(src: ArazzoFile, target: ArazzoFile) {
    src +>:DependsOn:+> target;
}
def get_ordered_paths(ws: Workspace) -> list[str] {
    files: list[ArazzoFile] = [ws ->:Holds:->][?:ArazzoFile];
    all_paths: list[str] = [];
    for f in files { all_paths.append(f.path); }
    all_paths = sorted(all_paths);
    lookup: dict[str, ArazzoFile] = {};
    for f in files { lookup[f.path] = f; }
    ordered: list[str] = [];
    placed: dict[str, bool] = {};
    ws spawn FileTraverseWalker(claimed={});
    for __ in all_paths {
        for p in all_paths {
            if p in placed { continue; }
            nd: ArazzoFile = lookup[p];
            deps: list[ArazzoFile] = [nd ->:DependsOn:->][?:ArazzoFile];
            ok: bool = True;
            for d in deps {
                if d.path in lookup {
                    if d.path not in placed { ok = False; }
                }
            }
            if ok {
                ordered.append(p);
                placed[p] = True;
            }
        }
    }
    return ordered;
}
def detect_cycle(ws: Workspace) -> str {
    ordered: list[str] = get_ordered_paths(ws);
    files: list[ArazzoFile] = [ws ->:Holds:->][?:ArazzoFile];
    if len(ordered) != len(files) {
        placed: dict[str, bool] = {};
        for p in ordered { placed[p] = True; }
        for f in files {
            if f.path not in placed {
                err = FileParseCycleException(message="cycle detected", cycle_path=f.path);
                root +>:Holds:+> err;
                print("FileParseCycleException at " + f.path);
                return f.path;
            }
        }
        return "cycle";
    }
    return "";
}
def parse_all_workspace(ws: Workspace) -> list[ArazzoDocument] {
    cyc: str = detect_cycle(ws);
    if cyc != "" {
        print("parse aborted cycle " + cyc);
        out: list[ArazzoDocument] = [];
        return out;
    }
    ordered: list[str] = get_ordered_paths(ws);
    result: list[ArazzoDocument] = [];
    for p in ordered {
        doc = ArazzoDocument(path=p);
        result.append(doc);
    }
    print("parsed workspace");
    return result;
}
def get_workspace_file_count(ws: Workspace) -> int {
    kids: list[ArazzoFile] = [ws ->:Holds:->][?:ArazzoFile];
    return len(kids);
}
with entry {
    ws = create_workspace("demo");
    s = add_file(ws, "schemas.arazzo.yaml", "schema");
    w = add_file(ws, "workflows/pay.arazzo.yaml", "workflow");
    add_schema_reference(w, s);
    root spawn FileTraverseWalker(claimed={});
    ws spawn FileTraverseWalker(claimed={});
    print("demo workspace ready");
}

test "diamond adversarial revisit ordering" {
    ws = create_workspace("diamond_adv");
    a = add_file(ws, "a.workflow.arazzo.yaml", "workflow");
    b = add_file(ws, "b.workflow.arazzo.yaml", "workflow");
    c = add_file(ws, "c.workflow.arazzo.yaml", "workflow");
    d = add_file(ws, "shared/schemas.arazzo.yaml", "schema");
    add_file_dependency(a, c);
    add_file_dependency(a, b);
    add_file_dependency(c, d);
    add_file_dependency(b, d);
    ordered = get_ordered_paths(ws);
    assert(len(ordered) == 4);
    pos_a: int = -1; pos_b: int = -1; pos_c: int = -1; pos_d: int = -1;
    idx: int = 0;
    for p in ordered {
        if p == "a.workflow.arazzo.yaml" { pos_a = idx; }
        if p == "b.workflow.arazzo.yaml" { pos_b = idx; }
        if p == "c.workflow.arazzo.yaml" { pos_c = idx; }
        if p == "shared/schemas.arazzo.yaml" { pos_d = idx; }
        idx = idx + 1;
    }
    assert(pos_d != -1); assert(pos_a != -1);
    assert(pos_d < pos_b); assert(pos_d < pos_c);
    assert(pos_b < pos_a); assert(pos_c < pos_a);
    docs = parse_all_workspace(ws);
    assert(len(docs) == 4);
}
test "cycle detection with file path context" {
    ws = create_workspace("cycle_ws");
    x = add_file(ws, "x.arazzo.yaml", "workflow");
    y = add_file(ws, "y.arazzo.yaml", "workflow");
    z = add_file(ws, "z.arazzo.yaml", "schema");
    add_file_dependency(x, y);
    add_file_dependency(y, z);
    add_file_dependency(z, x);
    cyc = detect_cycle(ws);
    assert(cyc != "");
    ordered = get_ordered_paths(ws);
    assert(len(ordered) != 3);
    docs = parse_all_workspace(ws);
    assert(len(docs) == 0);
}
test "unknown id tolerance" {
    ws = create_workspace("unknown_ws");
    a = add_file(ws, "workflows/a.arazzo.yaml", "workflow");
    b = add_file(ws, "workflows/b.arazzo.yaml", "workflow");
    ghost = ArazzoFile(path="missing/ghost.arazzo.yaml", kind="schema");
    add_file_dependency(a, ghost);
    add_file_dependency(b, a);
    ordered = get_ordered_paths(ws);
    assert(len(ordered) == 2);
    found_a: bool = False; found_b: bool = False;
    for p in ordered {
        if p == "workflows/a.arazzo.yaml" { found_a = True; }
        if p == "workflows/b.arazzo.yaml" { found_b = True; }
    }
    assert(found_a); assert(found_b);
    assert(detect_cycle(ws) == "");
}
test "both schema and sourceDescriptions as cross file refs" {
    ws = create_workspace("both_refs");
    schema = add_file(ws, "shared/common.arazzo.yaml", "schema");
    source = add_file(ws, "sources/external.arazzo.yaml", "source");
    wf = add_file(ws, "workflows/main.arazzo.yaml", "workflow");
    add_schema_reference(wf, schema);
    add_source_description_ref(wf, source);
    ordered = get_ordered_paths(ws);
    assert(len(ordered) == 3);
    pos_s: int = -1; pos_src: int = -1; pos_wf: int = -1;
    idx: int = 0;
    for p in ordered {
        if p == "shared/common.arazzo.yaml" { pos_s = idx; }
        if p == "sources/external.arazzo.yaml" { pos_src = idx; }
        if p == "workflows/main.arazzo.yaml" { pos_wf = idx; }
        idx = idx + 1;
    }
    assert(pos_s < pos_wf); assert(pos_src < pos_wf);
    assert(get_workspace_file_count(ws) == 3);
}
test "workspace DTO holds parsed collection" {
    ws = create_workspace("dto_ws");
    s1 = add_file(ws, "schemas/a.arazzo.yaml", "schema");
    w1 = add_file(ws, "workflows/w1.arazzo.yaml", "workflow");
    w2 = add_file(ws, "workflows/w2.arazzo.yaml", "workflow");
    add_file_dependency(w1, s1);
    add_file_dependency(w2, s1);
    assert(get_workspace_file_count(ws) == 3);
    ordered = get_ordered_paths(ws);
    assert(len(ordered) == 3);
    docs = parse_all_workspace(ws);
    assert(len(docs) == 3);
    has_s: bool = False;
    for d in docs { if d.path == "schemas/a.arazzo.yaml" { has_s = True; } }
    assert(has_s);
    assert(detect_cycle(ws) == "");
}
