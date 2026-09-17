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
