"""EffortlessMetrics/perl-lsp-swarm#7648 -- Moose canonical facts."""

node Pkg {
    has name: str;
}

node Attr {
    has key: str;
    has pkg: str;
    has attr: str;
    has is_mode: str;
}

edge Provides {}
edge Extends {}
edge Hook {}
edge Constraint {}

obj MooseRegistry {
    has pkgs: dict[str, Pkg] = {};
    has attrs: dict[str, Attr] = {};
}

def make_registry() -> MooseRegistry {
    return MooseRegistry();
}

def _pkg(reg: MooseRegistry, name: str) -> Pkg {
    if name in reg.pkgs { return reg.pkgs[name]; }
    p = Pkg(name=name);
    root ++> p;
    reg.pkgs[name] = p;
    return p;
}

def register_moose_attribute(reg: MooseRegistry, pkg: str, attr: str, is_mode: str | None, opts: dict) -> None {
    if is_mode is not None {
        ok = is_mode == "ro" or is_mode == "rw" or is_mode == "bare";
        if not ok { raise ValueError("invalid moose is_mode"); }
    }
    key = pkg + "::" + attr;
    if key in reg.attrs { raise ValueError("duplicate"); }
    p = _pkg(reg, pkg);
    mode_str = "";
    if is_mode is not None { mode_str = is_mode; }
    a = Attr(key=key, pkg=pkg, attr=attr, is_mode=mode_str);
    root ++> a;
    reg.attrs[key] = a;
    if is_mode == "ro" or is_mode == "rw" {
        p +>:Provides:+> a;
    }
    if "lazy_build" in opts {
        # builder hook
        bname = "_build_" + attr;
        bn = Attr(key=bname, pkg=pkg, attr=bname, is_mode="hook");
        root ++> bn;
        a +>:Hook:+> bn;
    } else {
        if "builder" in opts {
            bname = opts.get("builder", "");
            bn = Attr(key=bname, pkg=pkg, attr=bname, is_mode="hook");
            root ++> bn;
            a +>:Hook:+> bn;
        }
        if "trigger" in opts {
            tname = opts.get("trigger", "");
            tn = Attr(key=tname, pkg=pkg, attr=tname, is_mode="hook");
            root ++> tn;
            a +>:Hook:+> tn;
        }
    }
    if "isa" in opts {
        isa = opts.get("isa", None);
        if isa is not None {
            is_str = isinstance(isa, str);
            attr_val = isa if is_str else "dynamic";
            c = Attr(key=key + "#isa", pkg=pkg, attr=attr_val, is_mode="constraint");
            root ++> c;
            a +>:Constraint:+> c;
        }
    }
}

def add_extends(reg: MooseRegistry, child: str, parent: str) -> None {
    c = _pkg(reg, child);
    p = _pkg(reg, parent);
    p +>:Extends:+> c;
}

def provided_members(reg: MooseRegistry, pkg: str) -> list[str] {
    if not (pkg in reg.pkgs) { return []; }
    chain = ancestor_chain(reg, pkg);
    out: set[str] = set();
    for k in chain {
        for a in [reg.pkgs[k] ->:Provides:->][?:Attr] {
            out.add(a.attr);
        }
    }
    return sorted(list(out));
}

def referenced_hooks(reg: MooseRegistry, key: str) -> list[str] {
    if not (key in reg.attrs) { return []; }
    a = reg.attrs[key];
    hs: list[str] = [];
    for h in [a ->:Hook:->][?:Attr] { hs.append(h.attr); }
    return sorted(hs);
}

def constraint_for(reg: MooseRegistry, key: str) -> str | None {
    if not (key in reg.attrs) { return None; }
    a = reg.attrs[key];
    for c in [a ->:Constraint:->][?:Attr] { return c.attr; }
    return None;
}

def ancestor_chain(reg: MooseRegistry, pkg: str) -> list[str] {
    if not (pkg in reg.pkgs) { return []; }
    chain: list[str] = [];
    seen: set[str] = set();
    cur = pkg;
    while cur not in seen {
        chain.append(cur);
        seen.add(cur);
        found: str | None = None;
        for p in reg.pkgs {
            for ch in [reg.pkgs[p] ->:Extends:->][?:Pkg] {
                if ch.name == cur and p not in seen { found = p; }
            }
        }
        if found is None { break; }
        cur = found;
    }
    return chain;
}

test "bare and none produce no accessor" {
    reg = make_registry();
    register_moose_attribute(reg, "MyClass", "name", "ro", {});
    register_moose_attribute(reg, "MyClass", "bare_attr", "bare", {});
    register_moose_attribute(reg, "MyClass", "no_acc", None, {});
    assert provided_members(reg, "MyClass") == ["name"];
}

test "lazy_build hook" {
    reg = make_registry();
    register_moose_attribute(reg, "Foo", "x", "ro", {"lazy_build": True});
    assert referenced_hooks(reg, "Foo::x") == ["_build_x"];
}

test "constraint exact vs dynamic" {
    reg = make_registry();
    register_moose_attribute(reg, "Klass", "age", "rw", {"isa": "Int"});
    assert constraint_for(reg, "Klass::age") == "Int";
    register_moose_attribute(reg, "Klass2", "dyn", "rw", {"isa": 123});
    # int isa becomes dynamic marker
    val = constraint_for(reg, "Klass2::dyn");
    assert val == "dynamic";
}

test "inheritance chain" {
    reg = make_registry();
    register_moose_attribute(reg, "Base", "b", "ro", {});
    register_moose_attribute(reg, "Child", "c", "rw", {});
    add_extends(reg, "Child", "Base");
    assert provided_members(reg, "Child") == ["b", "c"];
    assert ancestor_chain(reg, "Child") == ["Child", "Base"];
}

test "invalid is_mode" {
    reg = make_registry();
    try {
        register_moose_attribute(reg, "X", "y", "rwp", {});
        assert False;
    } except ValueError { assert True; }
}
