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
