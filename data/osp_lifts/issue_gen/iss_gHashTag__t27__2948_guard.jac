""" gHashTag/t27#2948 - C backend self-referencing struct forward decl """

node Struct {
    has name: str;
}
node Registry {
    has name: str;
}
edge Holds {}
edge DependsOn {}

walker CollectFw {
    has claimed: dict[str, bool] = {};
    has names: list[str] = [];
    can step_reg with Registry entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        print("collect reg");
        kids: list[Struct] = [];
        for nd in [here ->:Holds:->][?:Struct] {
            kids.append(nd);
        }
        if len(kids) > 0 {
            visit :0: kids;
        }
    }
    can step_struct with Struct entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.names.append(here.name);
        print("collect struct");
    }
}

walker DemoWalk {
    has claimed: dict[str, bool] = {};
    can start with entry {
        print("demo start");
        kids: list[Registry] = [];
        for r in [here ->:Holds:->][?:Registry] {
            kids.append(r);
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
    can go_reg with Registry entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        print("demo reg");
    }
}

def find_struct(reg: Registry, name: str) -> Struct | None {
    for nd in [reg ->:Holds:->][?:Struct] {
        if nd.name == name {
            return nd;
        }
    }
    return None;
}

def make_registry() -> Registry {
    reg: Registry = Registry(name="root");
    return reg;
}

def add_struct(reg: Registry, name: str, deps: list[str] | None = None) {
    # no mutable default
    actual: list[str] = [];
    if deps == None {
        actual = [];
    } else {
        actual = deps;
    }
    nd: Struct | None = find_struct(reg, name);
    target: Struct;
    if nd == None {
        target = Struct(name=name);
        reg +>:Holds:+> target;
    } else {
        target = nd;
    }
    for dep_name in actual {
        dep_nd: Struct | None = find_struct(reg, dep_name);
        dep: Struct;
        if dep_nd == None {
            dep = Struct(name=dep_name);
            reg +>:Holds:+> dep;
        } else {
            dep = dep_nd;
        }
        already: bool = False;
        for ex in [target ->:DependsOn:->][?:Struct] {
            if ex.name == dep_name {
                already = True;
            }
        }
        if not already {
            target +>:DependsOn:+> dep;
        }
    }
}

def forward_decls(reg: Registry) -> list[str] {
    w = reg spawn CollectFw(claimed={}, names=[]);
    out: list[str] = [];
    for nm in w.names {
        out.append("typedef struct " + nm + " " + nm + ";");
    }
    out = sorted(out);
    return out;
}

def ordered_structs(reg: Registry) -> list[str] {
    w = reg spawn CollectFw(claimed={}, names=[]);
    all: list[str] = w.names;
    sorted_all: list[str] = sorted(all);
    placed: dict[str, bool] = {};
    out: list[str] = [];
    for attempt in range(len(sorted_all) + 1) {
        changed: bool = False;
        for nm in sorted_all {
            if nm in placed { continue; }
            nd: Struct | None = find_struct(reg, nm);
            if nd == None { continue; }
            ok: bool = True;
            for dep in [nd ->:DependsOn:->][?:Struct] {
                if dep.name == nm { continue; }
                if not (dep.name in placed) {
                    ok = False;
                }
            }
            if ok {
                out.append(nm);
                placed[nm] = True;
                changed = True;
            }
        }
        if not changed {
            for nm in sorted_all {
                if not (nm in placed) {
                    out.append(nm);
                    placed[nm] = True;
                }
            }
            break;
        }
        if len(out) == len(sorted_all) { break; }
    }
    return out;
}

def emit_c(reg: Registry) -> str {
    fwd: list[str] = forward_decls(reg);
    ord: list[str] = ordered_structs(reg);
    out: str = "";
    for line in fwd {
        out = out + line + "\n";
    }
    for nm in ord {
        out = out + "struct " + nm + " {\n";
        nd: Struct | None = find_struct(reg, nm);
        if nd != None {
            for dep in [nd ->:DependsOn:->][?:Struct] {
                out = out + "    " + dep.name + "* ptr;\n";
            }
        }
        out = out + "};\n";
    }
    return out;
}

with entry {
    tmp: Registry = Registry(name="demo");
    root +>:Holds:+> tmp;
    root spawn DemoWalk(claimed={});
}

test "self referencing struct is forward declared" {
    reg: Registry = make_registry();
    add_struct(reg, "BTreeNode", ["BTreeNode"]);
    fwd: list[str] = forward_decls(reg);
    assert(fwd == ["typedef struct BTreeNode BTreeNode;"]);
    c: str = emit_c(reg);
    assert("typedef struct BTreeNode BTreeNode;" in c);
    assert("struct BTreeNode {" in c);
}

test "diamond ordering respects dependencies adversarial" {
    reg: Registry = make_registry();
    add_struct(reg, "A", ["B", "C"]);
    add_struct(reg, "C", ["D"]);
    add_struct(reg, "B", ["D"]);
    add_struct(reg, "D", []);
    ord: list[str] = ordered_structs(reg);
    assert(ord == ["D", "B", "C", "A"]);
    fwd: list[str] = forward_decls(reg);
    assert(len(fwd) == 4);
}

test "mutual pointers both forward declared" {
    reg: Registry = make_registry();
    add_struct(reg, "L", ["R"]);
    add_struct(reg, "R", ["L"]);
    fwd: list[str] = forward_decls(reg);
    assert(len(fwd) == 2);
    assert("typedef struct L L;" in fwd);
    assert("typedef struct R R;" in fwd);
    ord: list[str] = ordered_structs(reg);
    assert(len(ord) == 2);
    c: str = emit_c(reg);
    assert("struct L {" in c);
    assert("struct R {" in c);
}

test "unknown and empty handled" {
    reg: Registry = make_registry();
    fwd: list[str] = forward_decls(reg);
    assert(len(fwd) == 0);
    ord: list[str] = ordered_structs(reg);
    assert(len(ord) == 0);
    c: str = emit_c(reg);
    assert(c == "");
    nd: Struct | None = find_struct(reg, "NoSuch");
    assert(nd == None);
}

test "every struct forward declared not only recursive" {
    reg: Registry = make_registry();
    add_struct(reg, "X", []);
    add_struct(reg, "Y", []);
    fwd: list[str] = forward_decls(reg);
    assert("typedef struct X X;" in fwd);
    assert("typedef struct Y Y;" in fwd);
    assert(len(fwd) == 2);
}
