node GraphRoot {
    has name: str = "root";
    has audit_enabled: bool = False;
}
node NodeDef {
    has name: str;
    has uses_audit_log: bool = False;
    has is_trigger: bool = False;
    has dirty: bool = True;
    has has_boolean_return: bool = True;
    has inject_service: str = "";
}
node ServiceDef {
    has name: str;
    has method_name: str = "m";
    has return_type: str = "void";
    has is_export: bool = False;
}
edge ParentLink {}
edge Depends {}
edge OwnsService {}

walker CollectNodes {
    has claimed: dict[str, bool] = {};
    has nodes: list[NodeDef] = [];
    has services: list[ServiceDef] = [];
    can start with GraphRoot entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        print("collect root " + here.name);
        for ch in [here ->:ParentLink:->][?:NodeDef] { visit :0: [ch]; }
        for sd in [here ->:OwnsService:->][?:ServiceDef] { visit :0: [sd]; }
    }
    can follow_node with NodeDef entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        print("collect node " + here.name);
        self.nodes.append(here);
        for ch in [here ->:ParentLink:->][?:NodeDef] { visit :0: [ch]; }
        for dep in [here ->:Depends:->][?:NodeDef] { visit :0: [dep]; }
    }
    can follow_svc with ServiceDef entry {
        key: str = here.name + ":" + here.method_name;
        if key in self.claimed { skip; }
        self.claimed[key] = True;
        print("collect svc " + here.name);
        self.services.append(here);
    }
}

walker ReachTarget {
    has claimed: dict[str, bool] = {};
    has target: str = "";
    has found: bool = False;
    can step with NodeDef entry {
        if self.found { skip; }
        if here.name == self.target {
            self.found = True;
            print("found " + here.name);
            skip;
        }
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        print("reach visit " + here.name);
        kids: list[NodeDef] = [here ->:Depends:->][?:NodeDef];
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def make_graph(audit_enabled: bool) -> GraphRoot {
    g = GraphRoot(name="root", audit_enabled=audit_enabled);
    root ++> g;
    return g;
}
def add_node(graph_root: GraphRoot, name: str, parent: NodeDef | None = None, uses_audit_log: bool = False, is_trigger: bool = False, dirty: bool = True, has_boolean_return: bool = True, inject_service: str = "") -> NodeDef {
    nd = NodeDef(name=name, uses_audit_log=uses_audit_log, is_trigger=is_trigger, dirty=dirty, has_boolean_return=has_boolean_return, inject_service=inject_service);
    if parent is not None {
        parent +>:ParentLink:+> nd;
    } else {
        graph_root +>:ParentLink:+> nd;
    }
    return nd;
}
def add_dependency(src: NodeDef, dst: NodeDef) {
    src +>:Depends:+> dst;
}
def add_service(graph_root: GraphRoot, svc_name: str, method: str, return_type: str, is_export: bool) -> ServiceDef {
    sd = ServiceDef(name=svc_name, method_name=method, return_type=return_type, is_export=is_export);
    graph_root +>:OwnsService:+> sd;
    return sd;
}
def validate(graph_root: GraphRoot) -> list[str] {
    collector = graph_root spawn CollectNodes;
    nodes: list[NodeDef] = collector.nodes;
    services: list[ServiceDef] = collector.services;
    violations: list[str] = [];
    seen_codes: dict[str, bool] = {};
    if not graph_root.audit_enabled {
        for nd in nodes {
            if nd.uses_audit_log {
                if not "FLX-1008" in seen_codes {
                    violations.append("FLX-1008");
                    seen_codes["FLX-1008"] = True;
                }
            }
        }
    }
    for svc in services {
        if svc.is_export and svc.return_type != "void" {
            if not "FLX-1002" in seen_codes {
                violations.append("FLX-1002");
                seen_codes["FLX-1002"] = True;
            }
        }
    }
    for nd in nodes {
        if nd.is_trigger and not nd.has_boolean_return {
            if not "FLX-1003" in seen_codes {
                violations.append("FLX-1003");
                seen_codes["FLX-1003"] = True;
            }
        }
    }
    seen_names: dict[str, bool] = {};
    for nd in nodes {
        if nd.name in seen_names {
            if not "FLX-1005" in seen_codes {
                violations.append("FLX-1005");
                seen_codes["FLX-1005"] = True;
            }
        } else {
            seen_names[nd.name] = True;
        }
    }
    for svc in services {
        if svc.name in seen_names {
            if not "FLX-1005" in seen_codes {
                violations.append("FLX-1005");
                seen_codes["FLX-1005"] = True;
            }
        }
    }
    svc_map: dict[str, bool] = {};
    for svc in services { svc_map[svc.name] = True; }
    for nd in nodes {
        if nd.inject_service != "" {
            if not nd.inject_service in svc_map {
                if not "FLX-1006" in seen_codes {
                    violations.append("FLX-1006");
                    seen_codes["FLX-1006"] = True;
                }
            }
        }
    }
    for nd in nodes {
        if nd.is_trigger and not nd.dirty {
            parents_root: list[GraphRoot] = [nd <-:ParentLink:-][?:GraphRoot];
            parents_node: list[NodeDef] = [nd <-:ParentLink:-][?:NodeDef];
            siblings: list[NodeDef] = [];
            if len(parents_root) > 0 {
                siblings = [parents_root[0] ->:ParentLink:->][?:NodeDef];
            } else {
                if len(parents_node) > 0 {
                    siblings = [parents_node[0] ->:ParentLink:->][?:NodeDef];
                }
            }
            if len(siblings) <= 1 {
                if not "FLX-1004" in seen_codes {
                    violations.append("FLX-1004");
                    seen_codes["FLX-1004"] = True;
                }
            }
        }
    }
    has_cycle: bool = False;
    for nd in nodes {
        deps: list[NodeDef] = [nd ->:Depends:->][?:NodeDef];
        for dep in deps {
            rt = dep spawn ReachTarget(target=nd.name);
            if rt.found {
                has_cycle = True;
                break;
            }
        }
        if has_cycle { break; }
    }
    if has_cycle {
        if not "FLX-1007" in seen_codes {
            violations.append("FLX-1007");
            seen_codes["FLX-1007"] = True;
        }
    }
    violations = sorted(violations);
    return violations;
}

with entry {
    demo = make_graph(False);
    n1 = add_node(demo, "demo1");
    c = demo spawn CollectNodes;
    print("demo nodes " + str(len(c.nodes)));
}

test "clean graph no violations" {
    g = make_graph(True);
    n1 = add_node(g, "a");
    n2 = add_node(g, "b", n1);
    add_service(g, "svc1", "m", "void", True);
    res = validate(g);
    assert(res == []);
}
test "FLX-1008 audit and FLX-1002 export void" {
    g = make_graph(False);
    n1 = add_node(g, "n1", None, True);
    add_service(g, "expSvc", "doIt", "int", True);
    res = validate(g);
    assert("FLX-1002" in res);
    assert("FLX-1008" in res);
    assert(len(res) == 2);
}
test "diamond revisit no false cycle" {
    g = make_graph(True);
    a = add_node(g, "a");
    b = add_node(g, "b");
    c = add_node(g, "c");
    d = add_node(g, "d");
    add_dependency(a, b);
    add_dependency(a, c);
    add_dependency(b, d);
    add_dependency(c, d);
    res = validate(g);
    assert(not "FLX-1007" in res);
}
test "cycle detection FLX-1007 and FLX-1003 FLX-1006" {
    g = make_graph(True);
    x = add_node(g, "x", None, False, True, True, False, "missingSvc");
    y = add_node(g, "y");
    z = add_node(g, "z");
    add_dependency(x, y);
    add_dependency(y, z);
    add_dependency(z, x);
    res = validate(g);
    assert("FLX-1007" in res);
    assert("FLX-1003" in res);
    assert("FLX-1006" in res);
}
test "FLX-1004 dirty and duplicate FLX-1005" {
    g = make_graph(True);
    parent = add_node(g, "parent");
    lone = add_node(g, "lone", parent, False, True, False, True, "");
    dup = add_node(g, "lone", parent);
    res = validate(g);
    assert("FLX-1004" in res);
    assert("FLX-1005" in res);
}
test "unknown id tolerance empty" {
    g = make_graph(True);
    res = validate(g);
    assert(res == []);
    g2 = make_graph(False);
    isolated = add_node(g2, "iso", None, False, False, True, True, "ghost");
    res2 = validate(g2);
    assert("FLX-1006" in res2);
}
