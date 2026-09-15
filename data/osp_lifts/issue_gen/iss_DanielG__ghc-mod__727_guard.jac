"""Synthetic OSP lift for DanielG/ghc-mod#727 — recursive module plusProv."""

node Module {
    has mid: str;
    has symbols: dict[str, str] = {};
    has type_spans: dict[str, str] = {};
}

edge Imports {}

node RegistryHandle {
    has by_id: dict[str, Module] = {};
}

walker ImportClosureWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Module entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        self.found.append(here.mid);
        print(here.mid);
        kids: list[Module] = [here ->:Imports:->][?:Module];
        for ch in kids {
            visit :0: [ch];
        }
    }
}

walker ProvWalker {
    has target: str;
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can step with Module entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        if self.target in here.symbols {
            self.chain.append(here.mid);
        }
        print(here.mid);
        kids: list[Module] = [here ->:Imports:->][?:Module];
        for ch in kids {
            visit :0: [ch];
        }
    }
}

def build_registry(specs: list[dict[str, any]]) -> RegistryHandle {
    handle = RegistryHandle(by_id={});
    for spec in specs {
        mid = spec["mid"] as str;
        nd = Module(mid=mid);
        syms: dict[str, str] = {};
        if "symbols" in spec {
            syms = spec["symbols"] as dict[str, str];
        }
        sym_keys = sorted(syms.keys());
        for sk in sym_keys {
            nd.symbols[sk] = syms[sk];
        }
        if "type_spans" in spec {
            spans = spec["type_spans"] as dict[str, str];
            span_keys = sorted(spans.keys());
            for tk in span_keys {
                nd.type_spans[tk] = spans[tk];
            }
        }
        handle.by_id[mid] = nd;
        root ++> nd;
    }
    for spec in specs {
        mid = spec["mid"] as str;
        src = handle.by_id[mid];
        imps: list[str] = [];
        if "imports" in spec {
            imps = spec["imports"] as list[str];
        }
        for imp in imps {
            imp_id = imp as str;
            if imp_id in handle.by_id {
                dst = handle.by_id[imp_id];
                src +>:Imports:+> dst;
            }
        }
    }
    return handle;
}

def import_closure(handle: RegistryHandle, module_id: str) -> list[str] {
    if module_id not in handle.by_id {
        return [];
    }
    start = handle.by_id[module_id];
    w = start spawn ImportClosureWalker(claimed={});
    out: list[str] = [];
    for mid in w.found {
        if mid != module_id {
            out.append(mid);
        }
    }
    return sorted(out);
}

def plus_prov(handle: RegistryHandle, module_id: str, symbol: str) -> list[str] {
    if module_id not in handle.by_id {
        return [];
    }
    start = handle.by_id[module_id];
    w = start spawn ProvWalker(target=symbol, claimed={});
    out: list[str] = [];
    for mid in w.chain {
        out.append(mid);
    }
    return out;
}

def module_type_at(handle: RegistryHandle, module_id: str, line: int, col: int) -> str {
    if module_id not in handle.by_id {
        return "";
    }
    nd = handle.by_id[module_id];
    loc_key = str(line) + ":" + str(col);
    if loc_key in nd.type_spans {
        return nd.type_spans[loc_key];
    }
    return "";
}

test "import_closure_cycle_sorted" {
    specs: list[dict[str, any]] = [
        {"mid": "A", "imports": ["B"]},
        {"mid": "B", "imports": ["A"]},
    ];
    handle = build_registry(specs);
    got = import_closure(handle, "A");
    assert got == ["B"];
}

test "plus_prov_recursive_modules" {
    specs: list[dict[str, any]] = [
        {"mid": "A", "symbols": {"foo": "t1"}, "imports": ["B"]},
        {"mid": "B", "symbols": {}, "imports": ["A"]},
    ];
    handle = build_registry(specs);
    got = plus_prov(handle, "B", "foo");
    assert got == ["A"];
}

test "plus_prov_includes_start_when_local" {
    specs: list[dict[str, any]] = [
        {"mid": "M", "symbols": {"bar": "t2"}, "imports": []},
    ];
    handle = build_registry(specs);
    got = plus_prov(handle, "M", "bar");
    assert got == ["M"];
}

test "plus_prov_unknown_module_empty" {
    specs: list[dict[str, any]] = [
        {"mid": "X", "symbols": {"z": "t"}, "imports": []},
    ];
    handle = build_registry(specs);
    got = plus_prov(handle, "MISSING", "z");
    assert got == [];
}

test "module_type_at_lookup" {
    specs: list[dict[str, any]] = [
        {"mid": "T", "type_spans": {"3:5": "Int"}, "imports": []},
    ];
    handle = build_registry(specs);
    got = module_type_at(handle, "T", 3, 5);
    assert got == "Int";
}

test "module_type_at_unknown_module" {
    specs: list[dict[str, any]] = [
        {"mid": "T", "type_spans": {"1:1": "Bool"}, "imports": []},
    ];
    handle = build_registry(specs);
    got = module_type_at(handle, "NOPE", 1, 1);
    assert got == "";
}
