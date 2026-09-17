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

# mohanagy/madar#739 — default-auto call graph preserving static namespace
# bracket calls: bracket form binds identically to dot form via import map.

node Module {
    has name: str;
}

node Func {
    has name: str;
    has module: str;
    has shadowed: bool = False;
}

edge Imports {
    has local: str;
}

edge Calls {
    has form: str = "dot";  # "dot" or "bracket"
}

# public registry: fresh per fixture, no module-level mutable state
obj Registry {
    has funcs: dict[str, Func];
    has mods: dict[str, Module];

    def:__init__ {
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
        self.mods[mod] ++> f;
        self.funcs[mod + "." + name] = f;
        return f;
    }

    def add_import(src: str, dst: str, local: str) {
        self.mods[src] +>: Imports(local=local) :+> self.mods[dst];
    }

    def add_call(src_key: str, dst_key: str, form: str) {
        self.funcs[src_key] +>: Calls(form=form) :+> self.funcs[dst_key];
    }

    # public: resolve a call binding; receiver is a local name, a shadowed
    # receiver or unknown callee resolves to None (no invented relations)
    def resolve_call(reg_mod: str, receiver: str, callee: str) -> str | None {
        local_key: str = reg_mod + "." + receiver;
        if local_key in self.funcs {
            if self.funcs[local_key].shadowed {
                return None;
            }
            if (reg_mod + "." + callee) in self.funcs {
                return reg_mod + "." + callee;
            }
            return None;
        }
        m: Module = self.mods[reg_mod];
        for tgt: Module in [m ->:Imports:->] {
            key: str = tgt.name + "." + callee;
            if key in self.funcs {
                return key;
            }
        }
        return None;
    }

    # public: build the call edge for either syntax form;
    # bracket resolves through the import map exactly as dot does
    def build_call(reg_mod: str, receiver: str, callee: str, form: str) -> str | None {
        dst: str | None = self.resolve_call(reg_mod, receiver, callee);
        if dst is None {
            return None;
        }
        self.add_call(reg_mod + "." + receiver, dst, form);
        return dst;
    }

    # public: all call-chain paths reachable from fn_key (closure);
    # unknown ids tolerate as empty list
    def call_chain(fn_key: str) -> list[list[str]] {
        if fn_key not in self.funcs {
            return [];
        }
        w = self.funcs[fn_key] spawn ChainWalker(claimed={}, paths=[], path=[]);
        out: list[list[str]] = sorted(w.paths);
        return out;
    }
}

walker ChainWalker {
    has claimed: dict[str, bool] = {};
    has paths: list[list[str]] = [];
    has path: list[str] = [];

    can step with Func entry {
        key: str = here.module + "." + here.name;
        if key in self.claimed {
            skip;  # cycle policy: claim-map, never disengage on revisit
        }
        self.claimed[key] = True;
        self.path.append(key);
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

with entry {
    reg = Registry();
    reg.add_module("main");
    reg.add_module("names");
    reg.add_func("names", "prepareName");
    reg.add_func("names", "trimName");
    reg.add_func("main", "renderGreeting");
    reg.add_import("main", "names", "names");
    # bracket form on imported namespace binds like dot form
    got = reg.build_call("main", "names", "prepareName", "bracket");
    reg.add_call("names.prepareName", "names.trimName", "dot");
    chains = reg.call_chain("main.renderGreeting");
    print(got);
    print(chains);
}

# mohanagy/madar#739 — default-auto call graph preserving static namespace
# bracket calls: bracket form binds identically to dot form via import map.

node Module {
    has name: str;
}

node Func {
    has name: str;
    has module: str;
    has shadowed: bool = False;
}

edge Imports {
    has local: str;
}

edge Calls {
    has form: str = "dot";  # "dot" or "bracket"
}

# public registry: fresh per fixture, no module-level mutable state
obj Registry {
    has funcs: dict[str, Func];
    has mods: dict[str, Module];

    def:__init__ {
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
        self.mods[mod] ++> f;
        self.funcs[mod + "." + name] = f;
        return f;
    }

    def add_import(src: str, dst: str, local: str) {
        self.mods[src] +>: Imports(local=local) :+> self.mods[dst];
    }

    def add_call(src_key: str, dst_key: str, form: str) {
        self.funcs[src_key] +>: Calls(form=form) :+> self.funcs[dst_key];
    }

    # public: resolve call binding; shadowed receiver or unknown callee
    # resolves to None — no invented import/call relations
    def resolve_call(reg_mod: str, receiver: str, callee: str) -> str | None {
        local_key: str = reg_mod + "." + receiver;
        if local_key in self.funcs {
            if self.funcs[local_key].shadowed {
                return None;
            }
            if (reg_mod + "." + callee) in self.funcs {
                return reg_mod + "." + callee;
            }
            return None;
        }
        m: Module = self.mods[reg_mod];
        for tgt: Module in [m ->:Imports:->] {
            key: str = tgt.name + "." + callee;
            if key in self.funcs {
                return key;
            }
        }
        return None;
    }

    # public: build call edge for either syntax form; bracket resolves
    # through the import map exactly as the dot form does
    def build_call(reg_mod: str, receiver: str, callee: str, form: str) -> str | None {
        dst: str | None = self.resolve_call(reg_mod, receiver, callee);
        if dst is None {
            return None;
        }
        self.add_call(reg_mod + "." + receiver, dst, form);
        return dst;
    }

    # public: all call-chain paths reachable from fn_key (closure);
    # unknown ids tolerated as empty list
    def call_chain(fn_key: str) -> list[list[str]] {
        if fn_key not in self.funcs {
            return [];
        }
        w = self.funcs[fn_key] spawn ChainWalker(claimed={}, paths=[], path=[]);
        return sorted(w.paths);
    }
}

walker ChainWalker {
    has claimed: dict[str, bool] = {};
    has paths: list[list[str]] = [];
    has path: list[str] = [];

    can step with Func entry {
        key: str = here.module + "." + here.name;
        if key in self.claimed {
            skip;  # cycle policy: claim-map + skip, never disengage on revisit
        }
        self.claimed[key] = True;
        self.path.append(key);
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

with entry {
    reg = Registry();
    reg.add_module("main");
    reg.add_module("names");
    reg.add_func("names", "prepareName");
    reg.add_func("names", "trimName");
    reg.add_func("main", "renderGreeting");
    reg.add_import("main", "names", "names");
    got = reg.build_call("main", "names", "prepareName", "bracket");
    reg.add_call("names.prepareName", "names.trimName", "dot");
    chains = reg.call_chain("main.renderGreeting");
    print(got);
    print(chains);
}

test "bracket equals dot through full chain" {
    reg = Registry();
    reg.add_module("main");
    reg.add_module("names");
    reg.add_func("names", "prepareName");
    reg.add_func("names", "trimName");
    reg.add_func("main", "renderGreeting");
    reg.add_import("main", "names", "names");
    b = reg.build_call("main", "names", "prepareName", "bracket");
    d = reg.build_call("main", "names", "prepareName", "dot");
    assert b == "names.prepareName";
    assert d == "names.prepareName";
    reg.add_call("names.prepareName", "names.trimName", "dot");
    reg.add_call("names.trimName", "main.renderGreeting", "dot");
    chains = reg.call_chain("main.renderGreeting");
    assert chains == [["main.renderGreeting", "names.prepareName", "names.trimName", "main.renderGreeting"]];
}

test "diamond revisit does not truncate closure" {
    reg = Registry();
    reg.add_module("m");
    reg.add_func("m", "a");
    reg.add_func("m", "b");
    reg.add_func("m", "c");
    reg.add_func("m", "d");
    reg.add_call("m.a", "m.b", "dot");
    reg.add_call("m.b", "m.d", "dot");
    reg.add_call("m.a", "m.c", "dot");
    # adversarial: deep d visited via b, then revisited via c — claim-map keeps closure
    reg.add_call("m.c", "m.d", "dot");
    reg.add_call("m.d", "m.a", "dot");
    chains = reg.call_chain("m.a");
    assert len(chains) >= 2;
    assert ["m.a", "m.b", "m.d", "m.a"] in chains;
    assert ["m.a", "m.c", "m.d", "m.a"] in chains;
}

test "shadowed receiver binds to nothing" {
    reg = Registry();
    reg.add_module("app");
    reg.add_module("util");
    reg.add_func("app", "util", shadowed=True);
    reg.add_func("util", "trim");
    reg.add_import("app", "util", "util");
    assert reg.build_call("app", "util", "trim", "bracket") is None;
    assert reg.build_call("app", "util", "trim", "dot") is None;
}

test "unresolved dynamic key tolerated" {
    reg = Registry();
    reg.add_module("app");
    reg.add_func("app", "run");
    reg.add_import("app", "app", "app");
    assert reg.build_call("app", "app", "nope", "bracket") is None;
    assert reg.call_chain("app.missing") == [];
}

test "no invented relations for empty registry" {
    reg = Registry();
    reg.add_module("x");
    assert reg.call_chain("x.anything") == [];
    assert reg.build_call("x", "nothing", "here", "bracket") is None;
}
