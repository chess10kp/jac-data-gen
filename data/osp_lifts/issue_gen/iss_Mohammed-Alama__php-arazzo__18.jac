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
