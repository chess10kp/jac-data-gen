"""EffortlessMetrics/perl-lsp-swarm#9473 — direct callable-result receiver transition."""

node CallSite {
    has call_id: str;
    has alternatives: list[str] = [];
}

obj CallStore {
    has calls: dict[str, CallSite] = {};
    has receivers: dict[str, str | None] = {};
}

def load_calls(
    call_ids: list[str],
    result_alternatives: dict[str, list[str]],
) -> CallStore {
    store = CallStore();
    for cid in call_ids {
        alts = result_alternatives.get(cid, []);
        nd = CallSite(call_id=cid, alternatives=alts);
        root ++> nd;
        store.calls[cid] = nd;
        store.receivers[cid] = None;
    }
    return store;
}

def _exact_object_alternatives(alts: list[str]) -> list[str] {
    exact: list[str] = [];
    for alt in alts {
        if alt.startswith("obj:") { exact.append(alt[4:]); }
    }
    return exact;
}

def direct_receiver(store: CallStore, call_id: str) -> str | None {
    cs = store.calls.get(call_id, None);
    if cs is None { return None; }
    exact = _exact_object_alternatives(cs.alternatives);
    if len(exact) == 1 { return exact[0]; }
    return None;
}

def receiver_outcome(store: CallStore, call_id: str) -> str {
    cs = store.calls.get(call_id, None);
    if cs is None { return "unavailable"; }
    exact = _exact_object_alternatives(cs.alternatives);
    if len(exact) == 1 { return "exact"; }
    if len(exact) > 1 { return "qualified"; }
    if any(a.startswith("obj:") for a in cs.alternatives) { return "qualified"; }
    return "unavailable";
}

def propagate_receiver(store: CallStore, call_id: str) -> str | None {
    if receiver_outcome(store, call_id) != "exact" { return None; }
    recv = direct_receiver(store, call_id);
    if recv is not None { store.receivers[call_id] = recv; }
    return recv;
}
