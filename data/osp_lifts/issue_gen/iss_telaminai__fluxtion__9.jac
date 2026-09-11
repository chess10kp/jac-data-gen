node BuildRoot {
    has has_audit: bool = False;
}
node CodeNode {
    has nid: str;
    has name: str;
    has return_type: str = "void";
    has is_export_method: bool = False;
    has is_handler: bool = False;
    has returns_bool: bool = True;
    has dirty: bool = True;
    has uses_audit_log: bool = False;
    has inject_service: str = "";
    has service_resolved: bool = True;
    has gen_id: str = "";
}
edge Depends {}
edge Parent {}
edge Contains {}

walker CollectWalker {
    has claimed: dict[str, bool] = {};
    has collected: list[CodeNode] = [];
    can collect_root with BuildRoot entry {
        if "BuildRoot" in self.claimed { skip; }
        self.claimed["BuildRoot"] = True;
        print("collect root");
        for nd in [here ->:Contains:->][?:CodeNode] {
            visit :0: [nd];
        }
        visit [] else { disengage; }
    }
    can collect_node with CodeNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.collected.append(here);
        print(here.nid);
        for nxt in [here ->:Depends:->][?:CodeNode] { visit :0: [nxt]; }
        for nxt in [here ->:Parent:->][?:CodeNode] { visit :0: [nxt]; }
        for nxt in [here <-:Parent:-][?:CodeNode] { visit :0: [nxt]; }
        visit [] else { disengage; }
    }
}

walker CycleWalker {
    has claimed: dict[str, bool] = {};
    has parent: dict[str, str] = {};
    has cycle_path: list[str] = [];
    has cycle_found: bool = False;
    can cycle_root with BuildRoot entry {
        if "BuildRoot" in self.claimed { skip; }
        self.claimed["BuildRoot"] = True;
        print("cycle root");
        for nd in [here ->:Contains:->][?:CodeNode] {
            if nd.nid not in self.claimed { self.parent[nd.nid] = "BuildRoot"; }
            visit :0: [nd];
        }
        visit [] else { disengage; }
    }
    can cycle_node with CodeNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        print(here.nid);
        for nxt in [here ->:Depends:->][?:CodeNode] {
            if nxt.nid in self.claimed {
                cur: str = here.nid;
                tmp: str = cur;
                is_anc: bool = False;
                while True {
                    if tmp == nxt.nid { is_anc = True; break; }
                    if tmp not in self.parent { break; }
                    tmp = self.parent[tmp];
                    if tmp == "BuildRoot" { break; }
                }
                if is_anc {
                    self.cycle_found = True;
                    rev: list[str] = [];
                    cur2: str = here.nid;
                    while True {
                        rev.append(cur2);
                        if cur2 == nxt.nid { break; }
                        if cur2 not in self.parent { rev.append(nxt.nid); break; }
                        cur2 = self.parent[cur2];
                        if cur2 == "BuildRoot" { rev.append(nxt.nid); break; }
                    }
                    fwd: list[str] = [];
                    idx: int = len(rev) - 1;
                    while idx >= 0 { fwd.append(rev[idx]); idx = idx - 1; }
                    if len(fwd) > 0 {
                        if fwd[len(fwd) - 1] != nxt.nid { fwd.append(nxt.nid); }
                    }
                    self.cycle_path = fwd;
                }
            } else {
                self.parent[nxt.nid] = here.nid;
                visit :0: [nxt];
            }
        }
        visit [] else { disengage; }
    }
}

def new_graph(has_audit: bool) -> BuildRoot {
    g = BuildRoot(has_audit=has_audit);
    return g;
}
def create_graph(has_audit: bool) -> BuildRoot { return new_graph(has_audit=has_audit); }

def add_code_node(graph_root: BuildRoot, nid: str, name: str, return_type: str = "void", is_export_method: bool = False, is_handler: bool = False, returns_bool: bool = True, dirty: bool = True, uses_audit_log: bool = False, inject_service: str = "", service_resolved: bool = True, gen_id: str = "") -> CodeNode {
    nd = CodeNode(nid=nid, name=name, return_type=return_type, is_export_method=is_export_method, is_handler=is_handler, returns_bool=returns_bool, dirty=dirty, uses_audit_log=uses_audit_log, inject_service=inject_service, service_resolved=service_resolved, gen_id=gen_id);
    graph_root +>:Contains:+> nd;
    return nd;
}
def add_node(graph_root: BuildRoot, nid: str, name: str) -> CodeNode { return add_code_node(graph_root, nid=nid, name=name); }

def add_dependency(graph_root: BuildRoot, src_id: str, dst_id: str) {
    src: CodeNode | None = None;
    dst: CodeNode | None = None;
    for nd in [graph_root ->:Contains:->][?:CodeNode] {
        if nd.nid == src_id { src = nd; }
        if nd.nid == dst_id { dst = nd; }
    }
    if src == None { return; }
    if dst == None { return; }
    s = src as CodeNode;
    d = dst as CodeNode;
    s +>:Depends:+> d;
}
def set_parent_link(graph_root: BuildRoot, child_id: str, parent_id: str) {
    child: CodeNode | None = None;
    par: CodeNode | None = None;
    for nd in [graph_root ->:Contains:->][?:CodeNode] {
        if nd.nid == child_id { child = nd; }
        if nd.nid == parent_id { par = nd; }
    }
    if child == None { return; }
    if par == None { return; }
    c = child as CodeNode;
    p = par as CodeNode;
    c +>:Parent:+> p;
}

def get_diagnostics(graph_root: BuildRoot) -> list[dict[str, str]] {
    diags: list[dict[str, str]] = [];
    collector = graph_root spawn CollectWalker();
    nodes: list[CodeNode] = collector.collected;
    if len(nodes) == 0 {
        for nd in [graph_root ->:Contains:->][?:CodeNode] { nodes.append(nd); }
    }
    for nd in nodes {
        if nd.is_export_method {
            if nd.return_type != "void" {
                d: dict[str, str] = {"code": "FLX-1002", "severity": "error", "message": nd.nid + " export must return void"};
                diags.append(d);
            }
        }
    }
    for nd in nodes {
        if nd.is_handler {
            if nd.returns_bool == False {
                d: dict[str, str] = {"code": "FLX-1003", "severity": "error", "message": nd.nid + " handler missing boolean return"};
                diags.append(d);
            }
        }
    }
    for nd in nodes {
        if nd.is_handler {
            if nd.dirty == False {
                pars: list[CodeNode] = [nd ->:Parent:->][?:CodeNode];
                if len(pars) == 0 {
                    d: dict[str, str] = {"code": "FLX-1004", "severity": "warning", "message": nd.nid + " dirty=false no sibling"};
                    diags.append(d);
                } else {
                    par = pars[0];
                    cnt: int = 0;
                    for other in nodes {
                        if other.nid == nd.nid { continue; }
                        op: list[CodeNode] = [other ->:Parent:->][?:CodeNode];
                        if len(op) > 0 {
                            if op[0].nid == par.nid { cnt = cnt + 1; }
                        }
                    }
                    if cnt == 0 {
                        d: dict[str, str] = {"code": "FLX-1004", "severity": "warning", "message": nd.nid + " dirty=false no sibling"};
                        diags.append(d);
                    }
                }
            }
        }
    }
    seen_name: dict[str, bool] = {};
    seen_nid: dict[str, bool] = {};
    seen_gen: dict[str, bool] = {};
    for nd in nodes {
        if nd.name in seen_name {
            d: dict[str, str] = {"code": "FLX-1005", "severity": "error", "message": "duplicate name " + nd.name};
            diags.append(d);
        } else { seen_name[nd.name] = True; }
        if nd.nid in seen_nid {
            d: dict[str, str] = {"code": "FLX-1005", "severity": "error", "message": "duplicate nid " + nd.nid};
            diags.append(d);
        } else { seen_nid[nd.nid] = True; }
        if nd.gen_id != "" {
            if nd.gen_id in seen_name {
                d: dict[str, str] = {"code": "FLX-1005", "severity": "error", "message": "collides gen " + nd.gen_id};
                diags.append(d);
            }
            if nd.name == nd.gen_id {
                d: dict[str, str] = {"code": "FLX-1005", "severity": "error", "message": "name collides gen " + nd.name};
                diags.append(d);
            }
            seen_gen[nd.gen_id] = True;
        }
        if nd.name in seen_gen {
            d: dict[str, str] = {"code": "FLX-1005", "severity": "error", "message": "name collides gen " + nd.name};
            diags.append(d);
        }
    }
    for nd in nodes {
        if nd.inject_service != "" {
            if nd.service_resolved == False {
                d: dict[str, str] = {"code": "FLX-1006", "severity": "error", "message": nd.nid + " unresolved inject " + nd.inject_service};
                diags.append(d);
            }
        }
    }
    if graph_root.has_audit == False {
        for nd in nodes {
            if nd.uses_audit_log {
                d: dict[str, str] = {"code": "FLX-1008", "severity": "error", "message": nd.nid + " auditLog without addEventAudit"};
                diags.append(d);
            }
        }
    }
    cyc = graph_root spawn CycleWalker();
    if cyc.cycle_found {
        path_str: str = "";
        first: bool = True;
        for p in cyc.cycle_path {
            if first { path_str = p; first = False; } else { path_str = path_str + " -> " + p; }
        }
        if path_str == "" { path_str = "cycle"; }
        d: dict[str, str] = {"code": "FLX-1007", "severity": "error", "message": path_str};
        diags.append(d);
    }
    return diags;
}
def diagnose(graph_root: BuildRoot) -> list[dict[str, str]] { return get_diagnostics(graph_root=graph_root); }
def validate(graph_root: BuildRoot) -> list[dict[str, str]] { return get_diagnostics(graph_root=graph_root); }

with entry {
    g = new_graph(has_audit=True);
    a = add_code_node(g, nid="demoA", name="DemoA", is_export_method=True, return_type="void");
    b = add_code_node(g, nid="demoB", name="DemoB", is_handler=True, returns_bool=True, dirty=True);
    ds = get_diagnostics(g);
    print(ds);
    root spawn CollectWalker();
    root spawn CycleWalker();
}
