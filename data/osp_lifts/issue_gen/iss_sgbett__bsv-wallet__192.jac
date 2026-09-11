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
