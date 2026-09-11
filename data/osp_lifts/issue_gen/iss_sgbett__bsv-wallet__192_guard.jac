node Wallet { has wallet_id: str; }
node BatchNode { has batch_id: str; }
node ActionNode {
    has action_id: str;
    has txid: str;
    has status: str;
    has is_no_send: bool;
    has is_send_with: bool;
    has batch_id: str;
    has known_txids: list[str];
}
edge BatchContains {}
edge ChangeLink {}
edge SendWithLink {}

walker BatchMembersWalker {
    has batch_target: str;
    has claimed: dict[str, bool] = {};
    has found: list[ActionNode] = [];
    can step_wallet with Wallet entry {
        if here.wallet_id in self.claimed { skip; }
        self.claimed[here.wallet_id] = True;
        print(f"collect wallet {here.wallet_id}");
        kids: list[BatchNode] = [here ->:BatchContains:->][?:BatchNode];
        for k in kids { visit :0: [k]; }
        if len(kids) == 0 { disengage; }
    }
    can step_batch with BatchNode entry {
        if here.batch_id in self.claimed { skip; }
        self.claimed[here.batch_id] = True;
        print(f"collect batch {here.batch_id}");
        if here.batch_id == self.batch_target {
            acts: list[ActionNode] = [here ->:BatchContains:->][?:ActionNode];
            for a in acts {
                if a.action_id not in self.claimed {
                    self.found.append(a);
                    self.claimed[a.action_id] = True;
                    print(f"collect action {a.action_id}");
                }
            }
        }
    }
}

walker ActionLookupWalker {
    has target_id: str;
    has claimed: dict[str, bool] = {};
    has result: ActionNode | None = None;
    can lookup_wallet with Wallet entry {
        if here.wallet_id in self.claimed { skip; }
        self.claimed[here.wallet_id] = True;
        print(f"lookup wallet {here.wallet_id}");
        kids: list[BatchNode] = [here ->:BatchContains:->][?:BatchNode];
        for k in kids { visit :0: [k]; }
        if len(kids) == 0 { disengage; }
    }
    can lookup_batch with BatchNode entry {
        if here.batch_id in self.claimed { skip; }
        self.claimed[here.batch_id] = True;
        print(f"lookup batch {here.batch_id}");
        acts: list[ActionNode] = [here ->:BatchContains:->][?:ActionNode];
        for a in acts {
            print(f"lookup sees {a.action_id}");
            if a.action_id == self.target_id { self.result = a; }
        }
    }
}

walker ChainWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    can chain_step with ActionNode entry {
        if here.action_id in self.claimed { skip; }
        self.claimed[here.action_id] = True;
        print(f"chain visit {here.action_id}");
        self.order.append(here.action_id);
        nxts: list[ActionNode] = [here ->:ChangeLink:->][?:ActionNode];
        for n in nxts {
            if n.action_id not in self.claimed { visit :0: [n]; }
        }
        sws: list[ActionNode] = [here ->:SendWithLink:->][?:ActionNode];
        for s in sws {
            if s.action_id not in self.claimed { visit :0: [s]; }
        }
    }
}

walker DemoWalker {
    has claimed: dict[str, bool] = {};
    can demo with Wallet entry {
        if here.wallet_id in self.claimed { skip; }
        self.claimed[here.wallet_id] = True;
        print(f"demo wallet {here.wallet_id}");
    }
}

def find_batch(wallet: Wallet, batch_id: str) -> BatchNode | None {
    batches: list[BatchNode] = [wallet ->:BatchContains:->][?:BatchNode];
    for b in batches { if b.batch_id == batch_id { return b; } }
    return None;
}

def find_action_node(wallet: Wallet, action_id: str) -> ActionNode | None {
    batches: list[BatchNode] = [wallet ->:BatchContains:->][?:BatchNode];
    for b in batches {
        acts: list[ActionNode] = [b ->:BatchContains:->][?:ActionNode];
        for a in acts { if a.action_id == action_id { return a; } }
    }
    return None;
}

def create_action(wallet: Wallet, action_id: str, txid: str, batch_id: str, is_no_send: bool, is_send_with: bool, no_send_change: list[str] | None = None, send_with: list[str] | None = None, known_txids: list[str] | None = None) -> ActionNode {
    # status derived from noSend primitive
    status: str = "nosend";
    if is_no_send == False { status = "broadcast"; }
    kj: list[str] = [];
    if known_txids is not None { kj = known_txids; }
    batch = find_batch(wallet, batch_id);
    if batch is None {
        batch = BatchNode(batch_id=batch_id);
        wallet +>:BatchContains:+> batch;
    }
    act = ActionNode(action_id=action_id, txid=txid, status=status, is_no_send=is_no_send, is_send_with=is_send_with, batch_id=batch_id, known_txids=kj);
    batch_c: BatchNode = batch;
    batch_c +>:BatchContains:+> act;
    if no_send_change is not None {
        for pid in no_send_change {
            parent = find_action_node(wallet, pid);
            if parent is not None {
                p: ActionNode = parent;
                p +>:ChangeLink:+> act;
            }
        }
    }
    if send_with is not None {
        for sid in send_with {
            sib = find_action_node(wallet, sid);
            if sib is not None {
                s: ActionNode = sib;
                act +>:SendWithLink:+> s;
                s +>:SendWithLink:+> act;
            }
        }
    }
    return act;
}

def get_batch_members(wallet: Wallet, batch_id: str) -> list[ActionNode] {
    w = wallet spawn BatchMembersWalker(batch_target=batch_id);
    return w.found;
}

def get_action(wallet: Wallet, action_id: str) -> ActionNode | None {
    w = wallet spawn ActionLookupWalker(target_id=action_id);
    return w.result;
}

def get_chain_order(wallet: Wallet, start_action_id: str) -> list[str] {
    start = find_action_node(wallet, start_action_id);
    if start is None { return []; }
    s: ActionNode = start;
    w = s spawn ChainWalker();
    return w.order;
}

def list_all_actions(wallet: Wallet) -> list[ActionNode] {
    out: list[ActionNode] = [];
    batches: list[BatchNode] = [wallet ->:BatchContains:->][?:BatchNode];
    for b in batches {
        acts: list[ActionNode] = [b ->:BatchContains:->][?:ActionNode];
        for a in acts { out.append(a); }
    }
    return out;
}

with entry {
    w = root spawn DemoWalker();
    print("demo done");
}

test "four_quadrants_isnosend_x_issendwith" {
    w = Wallet(wallet_id="w_q");
    root ++> w;
    a1 = create_action(w, "q1", "tx1", "qbatch", False, False);
    a2 = create_action(w, "q2", "tx2", "qbatch", True, False);
    a3 = create_action(w, "q3", "tx3", "qbatch", False, True);
    members = get_batch_members(w, "qbatch");
    assert(len(members) == 3);
    ids: list[str] = [];
    for m in members { ids.append(m.action_id); }
    assert("q1" in ids);
    assert("q2" in ids);
    assert("q3" in ids);
    # status correctness per quadrant
    assert(a1.status == "broadcast");
    assert(a2.status == "nosend");
    assert(a3.status == "broadcast");
}

test "diamond_revisit_no_duplicate_chain" {
    w = Wallet(wallet_id="w_d");
    root ++> w;
    a = create_action(w, "da", "txa", "diam", True, False);
    # adversarial insertion: c before b so revisit to d happens early
    c = create_action(w, "dc", "txc", "diam", True, False, no_send_change=["da"]);
    b = create_action(w, "db", "txb", "diam", True, False, no_send_change=["da"]);
    # d has two parents forming diamond da->db->dd and da->dc->dd
    d = create_action(w, "dd", "txd", "diam", True, False, no_send_change=["db"]);
    # add second parent edge manually to complete diamond via ChangeLink
    # db and dc both converge to dd; we already linked db->dd, now add dc->dd
    dc_node = get_action(w, "dc");
    dd_node = get_action(w, "dd");
    if dc_node is not None {
        if dd_node is not None {
            dc2: ActionNode = dc_node;
            dd2: ActionNode = dd_node;
            dc2 +>:ChangeLink:+> dd2;
        }
    }
    order = get_chain_order(w, "da");
    assert(len(order) == 4);
    assert("da" in order);
    assert("db" in order);
    assert("dc" in order);
    assert("dd" in order);
    # ensure no duplicates via set size
    uniq: dict[str, bool] = {};
    for x in order { uniq[x] = True; }
    assert(len(uniq) == 4);
}

test "unknown_id_tolerance_empty" {
    w = Wallet(wallet_id="w_u");
    root ++> w;
    create_action(w, "ua1", "txu1", "ubatch", True, False);
    members = get_batch_members(w, "nope_batch");
    assert(len(members) == 0);
    act = get_action(w, "ghost");
    assert(act == None);
    chain = get_chain_order(w, "ghost");
    assert(len(chain) == 0);
}

test "batch_isolation_and_sendwith" {
    w = Wallet(wallet_id="w_s");
    root ++> w;
    a1 = create_action(w, "sa1", "txs1", "batch_a", True, True);
    a2 = create_action(w, "sa2", "txs2", "batch_a", True, True, send_with=["sa1"]);
    members_a = get_batch_members(w, "batch_a");
    members_b = get_batch_members(w, "batch_b");
    assert(len(members_a) == 2);
    assert(len(members_b) == 0);
    chain = get_chain_order(w, "sa1");
    # sendWith creates bidirectional link, so chain from sa1 reaches sa2
    assert("sa1" in chain);
    assert("sa2" in chain);
}

test "known_txids_preserved_and_noSendChange_chain" {
    w = Wallet(wallet_id="w_k");
    root ++> w;
    klist: list[str] = [];
    klist.append("tx0");
    klist.append("tx1");
    a1 = create_action(w, "ka1", "txk1", "kbatch", True, False, known_txids=klist);
    a2 = create_action(w, "ka2", "txk2", "kbatch", True, False, no_send_change=["ka1"]);
    assert(len(a1.known_txids) == 2);
    assert("tx0" in a1.known_txids);
    order = get_chain_order(w, "ka1");
    assert(len(order) == 2);
    assert(order[0] == "ka1");
    assert("ka2" in order);
}
