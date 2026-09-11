"""EffortlessMetrics/perl-lsp-swarm#4908 -- Moo registry-backed facts."""

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

walker AncestorWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];
    can step with Pkg entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.hits.append(here.name);
        visit [->:Extends:->][?:Pkg];
    }
}

walker ProvidedWalk {
    has claimed: dict[str, bool] = {};
    has members: list[str] = [];
    can step with Pkg entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        for a in [here ->:Provides:->][?:Attr] {
            self.members.append(a.attr);
        }
        visit [->:Extends:->][?:Pkg];
    }
}

obj MooRegistry {
    has pkgs: dict[str, Pkg] = {};
    has attrs: dict[str, Attr] = {};
}

def make_registry() -> MooRegistry {
    return MooRegistry();
}

def _pkg(reg: MooRegistry, name: str) -> Pkg {
    if name in reg.pkgs { return reg.pkgs[name]; }
    p = Pkg(name=name);
    root ++> p;
    reg.pkgs[name] = p;
    return p;
}

def register_attribute(reg: MooRegistry, pkg: str, attr: str, is_mode: str, opts: dict) -> None {
    # validate is_mode: ro/rw/rwp/lazy only
    ok = is_mode == "ro" or is_mode == "rw" or is_mode == "rwp" or is_mode == "lazy";
    if not ok { raise ValueError("non-exact is mode"); }
    key = pkg + "::" + attr;
    if key in reg.attrs { raise ValueError("duplicate attribute"); }
    p = _pkg(reg, pkg);
    a = Attr(key=key, pkg=pkg, attr=attr, is_mode=is_mode);
    root ++> a;
    reg.attrs[key] = a;
    p +>:Provides:+> a;
    if is_mode == "rwp" {
        wkey = pkg + "::_set_" + attr;
        w = Attr(key=wkey, pkg=pkg, attr="_set_" + attr, is_mode="writer");
        root ++> w;
        reg.attrs[wkey] = w;
        p +>:Provides:+> w;
    }
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

def add_extends(reg: MooRegistry, child: str, parent: str) -> None {
    c = _pkg(reg, child);
    p = _pkg(reg, parent);
    p +>:Extends:+> c;
}

def provided_members(reg: MooRegistry, pkg: str) -> list[str] {
    if not (pkg in reg.pkgs) { return []; }
    # use walker from pkg following Extends? Actually we need to walk parents, but our Extends is parent->child, so walk reverse not trivial.
    # Instead collect by scanning attrs whose pkg is in ancestor chain.
    chain = ancestor_chain(reg, pkg);
    out: set[str] = set();
    for k in chain {
        for a in [reg.pkgs[k] ->:Provides:->][?:Attr] {
            out.add(a.attr);
        }
    }
    return sorted(list(out));
}

def referenced_hooks(reg: MooRegistry, attr_key: str) -> list[str] {
    if not (attr_key in reg.attrs) { return []; }
    a = reg.attrs[attr_key];
    hs: list[str] = [];
    for h in [a ->:Hook:->][?:Attr] { hs.append(h.attr); }
    return sorted(hs);
}

def ancestor_chain(reg: MooRegistry, pkg: str) -> list[str] {
    if not (pkg in reg.pkgs) { return []; }
    # walk up by finding parent: reverse edge lookup
    chain: list[str] = [];
    seen: set[str] = set();
    cur = pkg;
    while cur not in seen {
        chain.append(cur);
        seen.add(cur);
        # find parent: which node has Extends to cur
        found: str | None = None;
        for p in reg.pkgs {
            pkg_node = reg.pkgs[p];
            for ch in [pkg_node ->:Extends:->][?:Pkg] {
                if ch.name == cur and p not in seen {
                    found = p;
                }
            }
        }
        if found is None { break; }
        cur = found;
    }
    return chain;
}
