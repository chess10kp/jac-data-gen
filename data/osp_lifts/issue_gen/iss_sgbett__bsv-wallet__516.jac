"""sgbett/bsv-wallet#516 — Persistent verification cache over ancestor graph."""

node Tx {
    has tid: str;
    has verified: bool = False;
}

edge Spends {}

obj TxStore {
    has txs: dict[str, Tx] = {};
}

walker TxAncestor {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can step with Tx entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.chain.append(here.tid);
        parents = [here ->:Spends:->][?:Tx];
        if len(parents) == 0 { disengage; }
        pick = parents[0];
        for p in parents {
            if p.tid < pick.tid { pick = p; }
        }
        visit [pick];
    }
}

def load_tx_graph(
    tx_ids: list[str],
    spends_edges: list[tuple[str, str]],
) -> TxStore {
    ts = TxStore();
    for tid in tx_ids {
        nd = Tx(tid=tid);
        root ++> nd;
        ts.txs[tid] = nd;
    }
    for (child, parent) in spends_edges {
        c = ts.txs.get(child, None);
        p = ts.txs.get(parent, None);
        if c is not None and p is not None { c +>:Spends:+> p; }
    }
    return ts;
}

def unproven_ancestors(store: TxStore, tx_id: str) -> list[str] {
    nd = store.txs.get(tx_id, None);
    if nd is None { return []; }
    w = nd spawn TxAncestor(claimed={}, chain=[]);
    out: list[str] = [];
    for tid in w.chain {
        if tid == tx_id { continue; }
        t = store.txs.get(tid, None);
        if t is not None and not t.verified {
            out.append(tid);
        }
    }
    return sorted(out);
}

def mark_verified(store: TxStore, tx_id: str) -> bool {
    nd = store.txs.get(tx_id, None);
    if nd is None { return False; }
    nd.verified = True;
    return True;
}

def cache_hits(store: TxStore, tx_ids: list[str]) -> list[str] {
    out: list[str] = [];
    for tid in tx_ids {
        nd = store.txs.get(tid, None);
        if nd is not None and nd.verified {
            out.append(tid);
        }
    }
    return sorted(out);
}
