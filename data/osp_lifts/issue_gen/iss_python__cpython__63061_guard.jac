"""Exception chain traversal with cycle safety — python/cpython#63061."""

node Exc {
    has eid: str;
    has etype: str;
    has msg: str = "";
}

edge Cause {}

edge Context {}

obj ExcRegistry {
    has by_id: dict[str, Exc] = {};
}

walker CollectChain {
    has claimed: dict[str, bool] = {};
    has use_cause: bool = True;
    has types_out: list[str] = {};
    can step with Exc entry {
        if here.eid in self.claimed {
            skip;
        }
        self.claimed[here.eid] = True;
        self.types_out.append(here.etype);
        print({"chain_collect": here.etype});
        nexts: list[Exc] = [];
        if self.use_cause {
            for ch in [here ->:Cause:->][?:Exc] {
                nexts.append(ch);
            }
        } else {
            for ch in [here ->:Context:->][?:Exc] {
                nexts.append(ch);
            }
        }
        i = 0;
        while i < len(nexts) {
            j = i + 1;
            while j < len(nexts) {
                a = nexts[i] as Exc;
                b = nexts[j] as Exc;
                if b.eid < a.eid {
                    nexts[i] = b;
                    nexts[j] = a;
                }
                j += 1;
            }
            i += 1;
        }
        idx = len(nexts) - 1;
        while idx >= 0 {
            ch = nexts[idx] as Exc;
            visit :0: [ch];
            idx -= 1;
        }
    }
}

walker CycleCheck {
    has claimed: dict[str, bool] = {};
    has use_cause: bool = True;
    has cyclic: bool = False;
    can step with Exc entry {
        if here.eid in self.claimed {
            self.cyclic = True;
            print({"chain_cycle": here.eid});
            skip;
        }
        self.claimed[here.eid] = True;
        print({"chain_probe": here.etype});
        nexts: list[Exc] = [];
        if self.use_cause {
            for ch in [here ->:Cause:->][?:Exc] {
                nexts.append(ch);
            }
        } else {
            for ch in [here ->:Context:->][?:Exc] {
                nexts.append(ch);
            }
        }
        i = 0;
        while i < len(nexts) {
            j = i + 1;
            while j < len(nexts) {
                a = nexts[i] as Exc;
                b = nexts[j] as Exc;
                if b.eid < a.eid {
                    nexts[i] = b;
                    nexts[j] = a;
                }
                j += 1;
            }
            i += 1;
        }
        idx = len(nexts) - 1;
        while idx >= 0 {
            ch = nexts[idx] as Exc;
            visit :0: [ch];
            idx -= 1;
        }
    }
}

def create_registry() -> ExcRegistry {
    reg = ExcRegistry(by_id={});
    return reg;
}

def add_exception(reg: ExcRegistry, exc_id: str, exc_type: str, message: str = "") -> None {
    if exc_id in reg.by_id {
        return;
    }
    nd = Exc(eid=exc_id, etype=exc_type, msg=message);
    reg.by_id[exc_id] = nd;
    root ++> nd;
}

def set_cause(reg: ExcRegistry, from_id: str, to_id: str) -> None {
    src = reg.by_id[from_id] as Exc;
    dst = reg.by_id[to_id] as Exc;
    src +>:Cause:+> dst;
}

def set_context(reg: ExcRegistry, from_id: str, to_id: str) -> None {
    src = reg.by_id[from_id] as Exc;
    dst = reg.by_id[to_id] as Exc;
    src +>:Context:+> dst;
}

def iter_chain_types(reg: ExcRegistry, start_id: str, use_cause: bool = True) -> list[str] {
    if start_id not in reg.by_id {
        return [];
    }
    start_nd = reg.by_id[start_id] as Exc;
    w = start_nd spawn CollectChain(claimed={}, use_cause=use_cause, types_out=[]);
    return w.types_out;
}

def chain_contains_cycle(reg: ExcRegistry, start_id: str, use_cause: bool = True) -> bool {
    if start_id not in reg.by_id {
        return False;
    }
    start_nd = reg.by_id[start_id] as Exc;
    w = start_nd spawn CycleCheck(claimed={}, use_cause=use_cause, cyclic=False);
    return w.cyclic;
}

def format_exception_chain(reg: ExcRegistry, start_id: str, use_cause: bool = True) -> str {
    types = iter_chain_types(reg, start_id, use_cause);
    if len(types) == 0 {
        return "";
    }
    out = types[0];
    idx = 1;
    while idx < len(types) {
        out = out + " caused by " + types[idx];
        idx += 1;
    }
    return out;
}

test "linear_chain_types" {
    reg = create_registry();
    add_exception(reg, "e1", "RuntimeError");
    add_exception(reg, "e2", "ValueError");
    set_cause(reg, "e1", "e2");
    got = iter_chain_types(reg, "e1");
    assert got == ["RuntimeError", "ValueError"];
}

test "unknown_start_empty" {
    reg = create_registry();
    assert iter_chain_types(reg, "missing") == [];
    assert format_exception_chain(reg, "missing") == "";
    assert chain_contains_cycle(reg, "missing") == False;
}

test "format_chain_string" {
    reg = create_registry();
    add_exception(reg, "e1", "RuntimeError");
    add_exception(reg, "e2", "ValueError");
    set_cause(reg, "e1", "e2");
    got = format_exception_chain(reg, "e1");
    assert got == "RuntimeError caused by ValueError";
}

test "cycle_detect_true" {
    reg = create_registry();
    add_exception(reg, "e1", "RuntimeError");
    add_exception(reg, "e2", "ValueError");
    set_cause(reg, "e1", "e2");
    set_cause(reg, "e2", "e1");
    assert chain_contains_cycle(reg, "e1") == True;
    assert iter_chain_types(reg, "e1") == ["RuntimeError", "ValueError"];
}

test "diamond_revisit_adversarial" {
    reg = create_registry();
    add_exception(reg, "e1", "RuntimeError");
    add_exception(reg, "e2", "ValueError");
    add_exception(reg, "e3", "TypeError");
    set_cause(reg, "e1", "e2");
    set_cause(reg, "e1", "e3");
    set_cause(reg, "e3", "e2");
    got = iter_chain_types(reg, "e1", use_cause=True);
    assert got == ["RuntimeError", "ValueError", "TypeError"];
}

test "context_edges_mode" {
    reg = create_registry();
    add_exception(reg, "e1", "RuntimeError");
    add_exception(reg, "e2", "ValueError");
    set_context(reg, "e1", "e2");
    assert iter_chain_types(reg, "e1", use_cause=False) == ["RuntimeError", "ValueError"];
    assert iter_chain_types(reg, "e1", use_cause=True) == ["RuntimeError"];
}
