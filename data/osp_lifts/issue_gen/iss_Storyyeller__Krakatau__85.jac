"""Storyyeller/Krakatau#85 — recursive JSR must not halt decompilation."""

node Block {
    has bid: str;
    has ops: list[str] = [];
}

edge Flow {}
edge Jsr {}

node Cfg {
    has entry_bid: str = "";
}

def make_cfg(entry_bid: str) -> Cfg {
    c = Cfg(entry_bid=entry_bid);
    root ++> c;
    return c;
}

def make_block(bid: str, ops: list[str] | None = None) -> Block {
    op_list: list[str] = [];
    if ops is not None {
        for o in ops {
            op_list.append(o);
        }
    }
    b = Block(bid=bid, ops=op_list);
    return b;
}

def attach_block(cfg: Cfg, block: Block) {
    cfg ++> block;
}

def connect_flow(src: Block, dst: Block) {
    src +>:Flow:+> dst;
}

def connect_jsr(src: Block, dst: Block) {
    src +>:Jsr:+> dst;
}

def find_block(cfg: Cfg, bid: str) -> Block | None {
    for b in [-->] cfg {
        if b.bid == bid {
            return b;
        }
    }
    return None;
}

def collect_jsr_closure(cfg: Cfg, entry_bid: str) -> list[str] {
    start = find_block(cfg, entry_bid);
    if start is None {
        return [];
    }
    w = start spawn JsrClosureWalker(claimed={});
    out: list[str] = [];
    for x in w.found {
        out.append(x);
    }
    out.sort();
    return out;
}

def has_recursive_jsr(cfg: Cfg, entry_bid: str) -> bool {
    start = find_block(cfg, entry_bid);
    if start is None {
        return False;
    }
    w = start spawn JsrClosureWalker(claimed={});
    return w.saw_revisit;
}

def decompile_block_order(cfg: Cfg, entry_bid: str) -> list[str] {
    start = find_block(cfg, entry_bid);
    if start is None {
        return [];
    }
    w = start spawn FlowPlanWalker(claimed={});
    out: list[str] = [];
    for x in w.plan {
        out.append(x);
    }
    return out;
}

def build_issue85_fixture -> Cfg {
    cfg = make_cfg("main");
    main_b = make_block("main", ["jsr L1"]);
    l1 = make_block("L1", ["jsr L2", "jsr L1", "return"]);
    l2 = make_block("L2", ["astore_1", "pop", "ret 1"]);
    attach_block(cfg, main_b);
    attach_block(cfg, l1);
    attach_block(cfg, l2);
    connect_jsr(main_b, l1);
    connect_jsr(l1, l2);
    connect_jsr(l1, l1);
    return cfg;
}

walker JsrClosureWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has saw_revisit: bool = False;

    can walk_jsr with Block entry {
        print ["jsr", here.bid];
        if here.bid in self.claimed {
            self.saw_revisit = True;
            skip;
        }
        self.claimed[here.bid] = True;
        self.found.append(here.bid);
        nexts: list[Block] = [];
        for ch in [here ->:Jsr:->][?:Block] {
            nexts.append(ch);
        }
        visit :0: nexts else {
            disengage;
        }
    }
}

walker FlowPlanWalker {
    has claimed: dict[str, bool] = {};
    has plan: list[str] = [];

    can walk_flow with Block entry {
        print ["flow", here.bid];
        if here.bid in self.claimed {
            skip;
        }
        self.claimed[here.bid] = True;
        self.plan.append(here.bid);
        nexts: list[Block] = [];
        for ch in [here ->:Flow:->][?:Block] {
            nexts.append(ch);
        }
        visit :0: nexts else {
            disengage;
        }
    }
}
