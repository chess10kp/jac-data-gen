"""RPGHacker/asar#405 — unary parse depth limits and eval recursion guards."""

node Expr {
    has cid: str;
    has kind: str;
    has op: str = "";
    has val: float = 0.0;
    has fname: str = "";
}

edge Child {}

walker ParseProbe {
    has claimed: dict[str, bool] = {};
    has depth: int = 0;
    has max_depth: int = 100;
    has deepest: int = 0;

    can step with Expr entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.depth += 1;
        if self.depth > self.deepest { self.deepest = self.depth; }
        print {"probe": here.cid, "depth": self.depth};
        if self.depth > self.max_depth {
            print {"parse_error": "depth_exceeded", "at": here.cid};
            disengage;
        }
        kids: list[object] = [here ->:Child:->][?:Expr];
        visit :0: kids;
    }
}

walker EvalWalker {
    has claimed: dict[str, bool] = {};
    has vals: dict[str, float] = {};
    has depth: int = 0;
    has max_depth: int = 1000;
    has funcs: dict[str, str] = {};
    has call_stack: dict[str, bool] = {};
    has out: float = 0.0;
    has err: str = "";

    can ev with Expr entry {
        if here.cid in self.claimed {
            if here.cid in self.vals {
                self.out = self.vals[here.cid];
                print {"eval_cache": here.cid, "val": self.out};
            }
            skip;
        }
        if self.depth > self.max_depth {
            self.err = "depth_exceeded";
            print {"eval_error": self.err, "at": here.cid};
            disengage;
        }
        self.claimed[here.cid] = True;
        self.depth += 1;

        if here.kind == "lit" {
            self.out = here.val;
            self.vals[here.cid] = here.val;
            print {"eval_lit": here.cid, "val": here.val};
        } else if here.kind == "unop" {
            kids: list[object] = [here ->:Child:->][?:Expr];
            if kids {
                child: object = kids[0];
                wk = child spawn EvalWalker(
                    claimed=self.claimed,
                    vals=self.vals,
                    depth=self.depth,
                    max_depth=self.max_depth,
                    funcs=self.funcs,
                    call_stack=self.call_stack
                );
                v = wk.out;
                if wk.err != "" {
                    self.err = wk.err;
                    disengage;
                }
                if here.op == "-" { v = 0.0 - v; }
                self.out = v;
                self.vals[here.cid] = v;
                print {"eval_unop": here.cid, "op": here.op, "val": v};
            } else {
                visit [] else { disengage; }
            }
        } else if here.kind == "call" {
            if here.fname in self.call_stack and self.call_stack[here.fname] {
                self.err = "recursive_cycle";
                print {"eval_error": self.err, "fn": here.fname};
                disengage;
            }
            bcid = "";
            if here.fname in self.funcs { bcid = self.funcs[here.fname]; }
            else {
                self.err = "unknown_func";
                print {"eval_error": self.err, "fn": here.fname};
                disengage;
            }
            body = find_expr(bcid);
            if not body {
                self.err = "unknown_id";
                print {"eval_error": self.err, "id": bcid};
                disengage;
            }
            nstk: dict[str, bool] = {};
            for k in self.call_stack { nstk[k] = self.call_stack[k]; }
            nstk[here.fname] = True;
            be = body as Expr;
            wk = be spawn EvalWalker(
                claimed={},
                vals={},
                depth=self.depth,
                max_depth=self.max_depth,
                funcs=self.funcs,
                call_stack=nstk
            );
            if wk.err != "" {
                self.err = wk.err;
                disengage;
            }
            self.out = wk.out;
            self.vals[here.cid] = wk.out;
            print {"eval_call": here.cid, "fn": here.fname, "val": wk.out};
        }
        self.depth -= 1;
    }
}

def find_expr(cid: str) -> object {
    hits: list[object] = [];
    for nd in [root -->][?:Expr] {
        ex = nd as Expr;
        if ex.cid == cid { hits.append(nd); }
    }
    if len(hits) > 0 { return hits[0]; }
    return None;
}

def parse_unops(ops: list[str], lit_val: float, max_depth: int) -> tuple[str | None, str | None] {
    if len(ops) > max_depth {
        print {"parse_unops": "depth_exceeded", "ops": len(ops), "max": max_depth};
        return (None, "depth_exceeded");
    }
    lit = Expr(cid="lit0", kind="lit", val=lit_val);
    root ++> lit;
    cur: Expr = lit;
    i = 0;
    for op in ops {
        nid = "u" + str(i);
        un = Expr(cid=nid, kind="unop", op=op);
        root ++> un;
        un +>:Child:+> cur;
        cur = un;
        i += 1;
    }
    wk = cur spawn ParseProbe(claimed={}, max_depth=max_depth);
    print {"parse_unops": cur.cid, "deepest": wk.deepest};
    return (cur.cid, None);
}

def evaluate(root_cid: str, funcs: dict[str, str], max_depth: int) -> tuple[float | None, str | None] {
    nd = find_expr(root_cid);
    if not nd {
        print {"evaluate": "unknown_id", "cid": root_cid};
        return (None, "unknown_id");
    }
    ex = nd as Expr;
    wk = ex spawn EvalWalker(
        claimed={},
        vals={},
        funcs=funcs,
        max_depth=max_depth,
        call_stack={}
    );
    if wk.err != "" {
        print {"evaluate": wk.err, "cid": root_cid};
        return (None, wk.err);
    }
    print {"evaluate": root_cid, "val": wk.out};
    return (wk.out, None);
}

obj math_demo {
    with entry {
        ops: list[str] = ["-", "+"];
        (pcid, perr) = parse_unops(ops, 9.0, 20);
        print {"demo_parse": pcid, "err": perr};
        if pcid {
            pnd = find_expr(pcid);
            if pnd { pnd spawn ParseProbe(claimed={}, max_depth=20); }
            (val, eer) = evaluate(pcid, {}, 1000);
            print {"demo_eval": val, "err": eer};
        }
    }
}

test "parse_unops_ok" {
    ops: list[str] = ["-", "-"];
    (cid, err) = parse_unops(ops, 5.0, 10);
    assert (err is None);
    assert (cid is not None);
}

test "parse_unops_depth_exceeded" {
    ops: list[str] = [];
    i = 0;
    while i < 12 {
        ops.append("-");
        i += 1;
    }
    (cid, err) = parse_unops(ops, 1.0, 10);
    assert (cid is None);
    assert (err == "depth_exceeded");
}

test "evaluate_unop_chain" {
    ops: list[str] = ["-", "-"];
    (cid, pe) = parse_unops(ops, 5.0, 10);
    assert (pe is None);
    (val, ee) = evaluate(cid, {}, 100);
    assert (ee is None);
    assert (val == 5.0);
}

test "evaluate_depth_exceeded" {
    ops: list[str] = [];
    i = 0;
    while i < 20 {
        ops.append("-");
        i += 1;
    }
    (cid, pe) = parse_unops(ops, 1.0, 100);
    assert (pe is None);
    (val, ee) = evaluate(cid, {}, 5);
    assert (val is None);
    assert (ee == "depth_exceeded");
}

test "evaluate_recursive_cycle" {
    call = Expr(cid="call1", kind="call", fname="f");
    body = Expr(cid="body1", kind="call", fname="f");
    root ++> call;
    root ++> body;
    funcs: dict[str, str] = {"f": "body1"};
    (val, err) = evaluate("call1", funcs, 100);
    assert (val is None);
    assert (err == "recursive_cycle");
}

test "evaluate_unknown_id" {
    (val, err) = evaluate("missing_cid", {}, 100);
    assert (val is None);
    assert (err == "unknown_id");
}
