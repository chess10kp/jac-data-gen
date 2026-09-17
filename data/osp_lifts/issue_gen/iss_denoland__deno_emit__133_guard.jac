node Module {
    has specifier: str;
    has source: str;
}

edge Imports { }

# transpile a single module without walking its import tree
def transpile_single(root_module: Module) -> dict[str, str] {
    out: dict[str, str] = {};
    out[root_module.specifier] = emit_js(root_module);
    return out;
}

# transpile by walking the full import tree, collecting every reachable module
def transpile(root_module: Module) -> dict[str, str] {
    w = root_module spawn Transpiler(claimed={});
    return w.emitted;
}

walker Transpiler {
    has claimed: dict[str, bool] = {};
    has emitted: dict[str, str] = {};

    can step with Module entry {
        if here.specifier in self.claimed {
            skip;
        }
        self.claimed[here.specifier] = True;
        self.emitted[here.specifier] = emit_js(here);
        kids: list[Module] = [here ->:Imports:->][?:Module];
        visit kids;
    }
}

def emit_js(m: Module) -> str {
    # naive TS-to-JS stand-in: strip type annotations marker suffix
    return m.source.replace(": string", "").replace(": number", "");
}

def register(specifier: str, source: str) -> Module {
    nd = Module(specifier=specifier, source=source);
    root ++> nd;
    return nd;
}

def connect(from_m: Module, to_m: Module) {
    from_m +>:Imports:+> to_m;
}

test "diamond revisit claim map" {
    a = register("a.ts", "let a: string = \"x\";");
    b = register("b.ts", "let b: string = \"y\";");
    c = register("c.ts", "let c: string = \"z\";");
    d = register("d.ts", "let d: string = \"w\";");
    connect(a, b);
    connect(a, c);
    connect(b, d);
    connect(c, d);
    out = transpile(a);
    keys: list[str] = [];
    for k in out.keys() { keys.append(k); }
    assert sorted(keys) == ["a.ts", "b.ts", "c.ts", "d.ts"];
    assert d.specifier in out;
}

test "single module skips tree" {
    e = register("e.ts", "let e: string = \"1\";");
    f = register("f.ts", "let f: string = \"2\";");
    connect(e, f);
    out = transpile_single(e);
    ks: list[str] = [];
    for k in out.keys() { ks.append(k); }
    assert sorted(ks) == ["e.ts"];
}

test "full walk emits import too" {
    g = register("g.ts", "let g: string = \"a\";");
    h = register("h.ts", "let h: string = \"b\";");
    connect(g, h);
    out = transpile(g);
    assert "h.ts" in out;
}

test "unknown root empty closure" {
    iso = register("isolated.ts", "let x: number = 0;");
    out = transpile(iso);
    ks: list[str] = [];
    for k in out.keys() { ks.append(k); }
    assert ks == ["isolated.ts"];
}

test "cycle tolerated" {
    p = register("p.ts", "let p: string = \"p\";");
    q = register("q.ts", "let q: string = \"q\";");
    connect(p, q);
    connect(q, p);
    out = transpile(p);
    ks: list[str] = [];
    for k in out.keys() { ks.append(k); }
    assert sorted(ks) == ["p.ts", "q.ts"];
}
