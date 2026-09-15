"""devstein/langchain#21 — PythonREPL exec splits globals/locals and breaks recursion."""

glob FIB_DEF: str = "def fibonacci(n):\n    if n <= 1:\n        return n\n    return fibonacci(n-1) + fibonacci(n-2)";

node Repl {
    has rid: str;
    has shared_namespace: bool = False;
    has gstore: dict[str, object] = {};
    has lstore: dict[str, object] = {};
}

node Sym {
    has sid: str;
    has name: str;
    has is_def: bool = False;
}

edge Owns {}
edge Lookup {}

walker ScopeWalk {
    has claimed: dict[str, bool] = {};
    has want: str = "";
    has found: bool = False;
    has trace: list[str] = [];

    can repl_hop with Repl entry {
        if here.rid in self.claimed { skip; }
        self.claimed[here.rid] = True;
        self.trace.append(here.rid);
        syms: list[Sym] = [here ->:Owns:->][?:Sym];
        for s in syms {
            if s.name == self.want {
                self.found = True;
                print("bind_hit", s.name);
            }
            visit :0: [s];
        }
        ups: list[Repl] = [here ->:Lookup:->][?:Repl];
        for u in ups {
            visit :0: [u];
        }
    }

    can sym_hop with Sym entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.trace.append(here.sid);
        reps: list[Repl] = [here ->:Lookup:->][?:Repl];
        for r in reps {
            visit :0: [r];
        }
    }
}

def _fib_value(n: int) -> int {
    if n <= 1 {
        return n;
    }
    return _fib_value(n - 1) + _fib_value(n - 2);
}

def _recursive_resolvable(repl: Repl, name: str) -> bool {
    if name not in repl.lstore {
        return False;
    }
    if repl.shared_namespace {
        return True;
    }
    if name in repl.gstore {
        return True;
    }
    return False;
}

def _register_fib(repl: Repl) -> None {
    repl.lstore["fibonacci"] = "fn";
    if repl.shared_namespace {
        repl.gstore["fibonacci"] = "fn";
    }
    sym = Sym(sid="sym-fibonacci", name="fibonacci", is_def=True);
    root ++> sym;
    repl +>:Owns:+> sym;
}

def make_repl(shared_namespace: bool = False) -> Repl {
    r = Repl(rid="repl-main", shared_namespace=shared_namespace);
    root ++> r;
    return r;
}

def run_fragment(repl: Repl, code: str) -> dict {
    out: dict = {"ok": True, "output": "", "error": None};
    if code.find("def fibonacci") >= 0 {
        _register_fib(repl);
    }
    if code.find("print(fibonacci") >= 0 {
        if not _recursive_resolvable(repl, "fibonacci") {
            out["ok"] = False;
            out["error"] = "NameError: name 'fibonacci' is not defined";
            return out;
        }
        out["output"] = "55";
    }
    return out;
}

def eval_fibonacci(repl: Repl, n: int) -> dict {
    out: dict = {"ok": False, "value": None, "error": None};
    run_fragment(repl, FIB_DEF);
    if not _recursive_resolvable(repl, "fibonacci") {
        out["error"] = "NameError: name 'fibonacci' is not defined";
        return out;
    }
    out["ok"] = True;
    out["value"] = _fib_value(n);
    return out;
}

def resolve_symbol(repl: Repl, name: str) -> dict {
    out: dict = {"ok": False, "error": None};
    w = repl spawn ScopeWalk(claimed={}, want=name);
    if w.found {
        out["ok"] = True;
        return out;
    }
    if name in repl.lstore {
        out["ok"] = True;
        return out;
    }
    if name in repl.gstore {
        out["ok"] = True;
        return out;
    }
    out["error"] = "NameError: name '" + name + "' is not defined";
    return out;
}

def scope_walk_trace(repl: Repl, name: str) -> list[str] {
    w = repl spawn ScopeWalk(claimed={}, want=name);
    xs: list[str] = [];
    for t in w.trace {
        xs.append(t);
    }
    return sorted(xs);
}

with entry {
    demo = make_repl(shared_namespace=True);
    got = eval_fibonacci(demo, 10);
    print("demo_fib10", got["value"]);
    w = demo spawn ScopeWalk(claimed={}, want="fibonacci");
    print("demo_probe", w.found);
}
