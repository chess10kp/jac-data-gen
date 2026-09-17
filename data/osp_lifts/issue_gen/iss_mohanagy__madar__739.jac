# mohanagy/madar#739 — call graph with static namespace bracket calls
# preserved: bracket form resolves identically to dot form via import map.

import from random { choice }

node Func {
    has name: str;
    has module: str;
    has shadowed: bool = False;
}

node Module {
    has name: str;
}

edge Imports { has source: str = ""; }
edge Calls { has form: str = "dot"; }   # form: "dot" or "bracket"

obj Registry {
    has funcs: dict[str, Func];
    has mods: dict[str, Module];

    def init() {
        self.funcs = {};
        self.mods = {};
    }

    def add_module(name: str) -> Module {
        m: Module = Module(name=name);
        root ++> m;
        self.mods[name] = m;
        return m;
    }

    def add_func(mod: str, name: str, shadowed: bool = False) -> Func {
        f: Func = Func(name=name, module=mod, shadowed=shadowed);
        m: Module = self.mods[mod];
        m ++> f;
        self.funcs[mod + "." + name] = f;
        return f;
    }

    def add_import(src: str, dst: str, local: str) {
        sm: Module = self.mods[src];
        dm: Module = self.mods[dst];
        e: Imports = sm +>: Imports(source=local) :+> dm;
        e.source = local;
    }

    # bind a call target: receiver resolves through import map;
    # shadowed receivers and unknown callees bind to nothing
    def resolve_call(mod: str, receiver: str, callee: str) -> str | None {
        local_key: str = mod + "." + receiver;
        if local_key in self.funcs {
            f: Func = self.funcs[local_key];
            if f.shadowed { return None; }
            return mod + "." + callee;
        }
        imp_target: str | None = self.resolve_import(mod, receiver, callee);
        if imp_target is None { return None; }
        return imp_target;
    }

    def resolve_import(mod: str, receiver: str, callee: str) -> str | None {
        m: Module = self.mods[mod];
        for im in [m ->:Imports:->] {
            if im.name == receiver {
                key: str = im.name_of_module() + "." + callee;
            }
        }
        # resolve via module connections
        for tgt: Module in [m ->:Imports:->]:Module {
            k: str = tgt.name + "." + callee;
            if k in self.funcs {
                return k;
            }
        }
        return None;
    }

    def add_call(src_key: str, dst_key: str, form: str) {
        a: Func = self.funcs[src_key];
        b: Func = self.funcs[dst_key];
        a +>: Calls(form=form) :+> b;
    }

    def build_call(src: str, receiver: str, callee: str, form: str) -> str | None {
        dst: str | None = self.resolve_call(src, receiver, callee);
        if dst is None { return None; }
        self.add_call(src + "." + receiver if False else src + "." + receiver, dst, form);
        return dst;
    }
}

# helper: dot access of module name off Module node
def name_of_module(m: Module) -> str {
    return m.name;
}

# node extension for Module to expose name in resolve_import
def Module.name_of_module() -> str {
    return self.name;
}

# walker: enumerate all call chains from a function, claim-map + skip cycles
walker ChainWalker {
    has target: str = "";
    has claimed: dict[str, bool] = {};
    has paths: list[list[str]] = [];
    has path: list[str] = [];

    can start with Func entry {
        if here.name + "|" + here.module in self.claimed { skip; }
        self.claimed[here.name + "|" + here.module] = True;
        self.path.append(here.module + "." + here.name);
        kids: list[Func] = [here ->:Calls:->][?:Func];
        if len(kids) == 0 {
            self.paths.append(self.path + []);
        }
        for kid in kids {
            visit kid;
        }
        self.path.pop();
    }
}

# public: full call chain (closure) from a function key, sorted
def call_chain(reg: Registry, fn_key: str) -> list[list[str]] {
    if fn_key not in reg.funcs {
        return [];
    }
    w: ChainWalker = reg.funcs[fn_key] spawn ChainWalker(claimed={}, paths=[], path=[], target=fn_key);
    out: list[list[str]] = [];
    for p in w.paths {
        out.append(p);
    }
    return sorted(out);
}

with entry {
    reg: Registry = Registry();
    reg.add_module("main");
    reg.add_module("names");
    reg.add_func("names", "prepareName");
    reg.add_func("names", "trimName");
    reg.add_func("main", "renderGreeting");
    reg.add_import("main", "names", "names");
    reg.add_call("main.renderGreeting", "names.prepareName", "bracket");
    reg.add_call("names.prepareName", "names.trimName", "dot");
    chains: list[list[str]] = call_chain(reg, "main.renderGreeting");
    print(chains);
}
