"""devstein/langchain#23 — PythonREPL globals/locals scope breaks recursive name lookup."""

node Scope {
    has sid: str;
    has bindings: dict[str, int] = {};
}

edge Inherits {}

node PythonREPL {
    has globals: dict[str, int] = {};
    has locals: dict[str, int] = {};
    def run(command: str) -> str {
        if "fibonacci" not in command {
            return "";
        }
        self.locals["fibonacci"] = 1;
        n: int = parse_fib_arg(command);
        g: Scope = dict_to_scope(self.globals, "globals");
        root ++> g;
        w: Lookup = g spawn Lookup(target="fibonacci", claimed={});
        if w.found == False {
            return "NameError:name 'fibonacci' is not defined";
        }
        ans: int = eval_fib(n);
        return str(ans);
    }
}

walker Lookup {
    has target: str;
    has found: bool = False;
    has claimed: dict[str, bool] = {};
    can lookup with Scope entry {
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        print("lookup", here.sid, self.target);
        if self.target in here.bindings {
            self.found = True;
            disengage;
        }
        pars: list[Scope] = [here ->:Inherits:->][?:Scope];
        for p in pars {
            visit :0: p;
        }
    }
}

walker Boot {
    has claimed: dict[str, bool] = {};
    can boot with Scope entry {
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        print("boot", here.sid);
    }
}

def dict_to_scope(d: dict[str, int], sid: str) -> Scope {
    s: Scope = Scope(sid=sid, bindings={});
    for k in sorted(d) {
        s.bindings[k] = d[k];
    }
    return s;
}

def parse_fib_arg(cmd: str) -> int {
    tag: str = "fibonacci(";
    i: int = 0;
    while i < len(cmd) {
        if i + len(tag) <= len(cmd) {
            ok: bool = True;
            j: int = 0;
            while j < len(tag) {
                if cmd[i + j] != tag[j] {
                    ok = False;
                }
                j = j + 1;
            }
            if ok {
                p: int = i + len(tag);
                num: str = "";
                while p < len(cmd) and cmd[p] >= "0" and cmd[p] <= "9" {
                    num = num + cmd[p];
                    p = p + 1;
                }
                if len(num) > 0 {
                    return int(num);
                }
            }
        }
        i = i + 1;
    }
    return 0;
}

def eval_fib(n: int) -> int {
    if n <= 1 {
        return n;
    }
    a: int = eval_fib(n - 1);
    b: int = eval_fib(n - 2);
    return a + b;
}

with entry {
    boot_scope: Scope = Scope(sid="boot", bindings={});
    root ++> boot_scope;
    root spawn Boot(claimed={});
}

test "repl_empty_command" {
    r: PythonREPL = PythonREPL(globals={}, locals={});
    root ++> r;
    out: str = r.run("print(1)");
    assert out == "";;
}

test "repl_name_error_without_global" {
    r: PythonREPL = PythonREPL(globals={}, locals={});
    root ++> r;
    out: str = r.run("fibonacci(5)");
    assert out == "NameError:name 'fibonacci' is not defined";;
}

test "repl_ok_with_global" {
    g: dict[str, int] = {};
    g["fibonacci"] = 1;
    r: PythonREPL = PythonREPL(globals=g, locals={});
    root ++> r;
    out: str = r.run("fibonacci(5)");
    assert out == "5";;
}

test "lookup_finds_in_parent" {
    par: Scope = Scope(sid="par", bindings={});
    par.bindings["x"] = 7;
    ch: Scope = Scope(sid="ch", bindings={});
    ch +>:Inherits:+> par;
    root ++> ch;
    w: Lookup = ch spawn Lookup(target="x", claimed={});
    assert w.found == True;;
}

test "diamond_inherit_resolve_revisit" {
    gp: Scope = Scope(sid="gp", bindings={});
    gp.bindings["fibonacci"] = 1;
    p1: Scope = Scope(sid="p1", bindings={});
    p2: Scope = Scope(sid="p2", bindings={});
    l: Scope = Scope(sid="l", bindings={});
    l +>:Inherits:+> p2;
    l +>:Inherits:+> p1;
    p1 +>:Inherits:+> gp;
    p2 +>:Inherits:+> gp;
    root ++> l;
    w: Lookup = l spawn Lookup(target="fibonacci", claimed={});
    assert w.found == True;;
}
