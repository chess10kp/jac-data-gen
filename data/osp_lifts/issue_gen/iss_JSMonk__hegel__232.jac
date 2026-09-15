"""JSMonk/hegel#232 — recursive function inference (OSP lift)."""

node Fn {
    has name: str;
    has inferred: str = "";
}

node Lit {
    has typ: str = "number";
}

node Branch {
    has tag: str;
}

node Invoke {
    has callee: str;
    has cid: str = "";
}

edge Body {}
edge Then {}
edge Else {}
edge Callee {}

walker RecursiveInfer {
    has claimed: dict[str, bool] = {};
    has out_type: str = "unknown";

    can infer_fn with Fn entry {
        if here.name in self.claimed {
            if here.inferred != "" {
                self.out_type = here.inferred;
            } else {
                self.out_type = "number";
            }
            print({"infer": here.name, "phase": "skip"});
            skip;
        }
        self.claimed[here.name] = True;
        here.inferred = "number";
        self.out_type = "number";
        print({"infer": here.name, "phase": "claim"});
        nexts: list[object] = [];
        for ch in [here ->:Body:->][?:object] {
            nexts.append(ch);
        }
        if len(nexts) > 0 {
            visit :0: nexts;
        } else {
            disengage;
        }
    }

    can infer_lit with Lit entry {
        self.out_type = here.typ;
        print({"infer": "lit", "type": here.typ});
        disengage;
    }

    can infer_branch with Branch entry {
        kids: list[object] = [];
        for ch in [here ->:Then:->][?:object] {
            kids.append(ch);
        }
        for ch in [here ->:Else:->][?:object] {
            kids.append(ch);
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
        self.out_type = "number";
        print({"infer": "branch", "tag": here.tag});
    }

    can infer_invoke with Invoke entry {
        if here.cid != "" {
            if here.cid in self.claimed {
                self.out_type = "number";
                print({"infer": "invoke", "cid": here.cid, "phase": "skip"});
                skip;
            }
            self.claimed[here.cid] = True;
        }
        self.out_type = "number";
        print({"infer": "invoke", "callee": here.callee});
        targets: list[Fn] = [];
        for ch in [here ->:Callee:->][?:Fn] {
            targets.append(ch);
        }
        if len(targets) > 0 {
            visit :0: targets;
        } else {
            disengage;
        }
    }
}

def wire_factorial(f: Fn, br: Branch, lit: Lit, inv: Invoke) -> None {
    f +>:Body:+> br;
    br +>:Then:+> lit;
    br +>:Else:+> inv;
    inv +>:Callee:+> f;
}

def make_factorial_graph() -> Fn {
    fac = Fn(name="factorial");
    root ++> fac;
    br = Branch(tag="a_eq_1");
    root ++> br;
    lit = Lit(typ="number");
    root ++> lit;
    inv = Invoke(callee="factorial");
    root ++> inv;
    wire_factorial(fac, br, lit, inv);
    return fac;
}

def make_diamond_recursive_graph() -> Fn {
    fac = Fn(name="diamond_fn");
    root ++> fac;
    br = Branch(tag="split");
    root ++> br;
    merge = Invoke(callee="diamond_fn", cid="merge_shared");
    root ++> merge;
    fac +>:Body:+> br;
    br +>:Then:+> merge;
    br +>:Else:+> merge;
    merge +>:Callee:+> fac;
    return fac;
}

def infer_fn(start: Fn) -> str {
    w = start spawn RecursiveInfer(claimed={});
    print({"result": w.out_type});
    return w.out_type;
}

def infer_by_name(fn_name: str) -> str {
    if fn_name == "" {
        return "";
    }
    found: Fn | None = None;
    for nd in [root -->][?:Fn] {
        if nd.name == fn_name {
            found = nd;
        }
    }
    if found is None {
        return "";
    }
    return infer_fn(found);
}

with entry {
    g = make_factorial_graph();
    infer_fn(g);
}
