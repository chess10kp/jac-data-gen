"""EffortlessMetrics/perl-lsp-swarm#12317 -- compiler_static_project cutline."""

glob PASS: str = "pass";
glob FAILED: str = "failed";
glob NOT_PROVEN: str = "not_proven";
glob STALE: str = "stale";

node Receipt {
    has rid: str;
    has rgroup: str;
    has verdict: str;
    has current: bool = True;
    has status: str = "pass";
}

edge Depends {}

obj CutlineStore {
    has receipts: dict[str, Receipt] = {};
}

walker ClosureWalk {
    has claimed: dict[str, bool] = {};
    has hits: set[str] = set();
    can step with Receipt entry {
        self.hits.add(here.rid);
        if here.rid in self.claimed { skip; }
        self.claimed[here.rid] = True;
        visit [->:Depends:->][?:Receipt];
    }
}

def _binding_key(candidate: dict) -> tuple {
    return (candidate.get("sha", None), candidate.get("profile_digest", None), candidate.get("root_generation", None), candidate.get("toolchain", None));
}

def _all_current(receipts: list[dict], key: tuple) -> bool {
    for r in receipts {
        if _binding_key(r.get("candidate", {})) != key { return False; }
        if r.get("status", "") == STALE or r.get("status", "") == NOT_PROVEN { return False; }
        if not r.get("current", True) { return False; }
    }
    return True;
}

def evaluate_cutline(candidate: dict, receipts: list[dict], limitations: list[str]) -> dict {
    # build graph for closure
    store = CutlineStore();
    mp: dict[str, Receipt] = {};
    for r in receipts {
        rid = r.get("id", "");
        if rid not in mp {
            nd = Receipt(rid=rid, rgroup=r.get("group", ""), verdict=r.get("verdict", ""), current=r.get("current", True), status=r.get("status", "pass"));
            root ++> nd;
            mp[rid] = nd;
            store.receipts[rid] = nd;
        }
    }
    for r in receipts {
        rid = r.get("id", "");
        dep_list: list[str] = r.get("depends_on", []);
        for dep in dep_list {
            if dep in mp and rid in mp {
                mp[dep] +>:Depends:+> mp[rid];
            }
        }
    }
    key = _binding_key(candidate);
    # collect failed closure via walker from each failed node
    failed_ids: list[str] = [];
    for r in receipts {
        if r.get("verdict", "") == FAILED {
            failed_ids.append(r.get("id", ""));
        }
    }
    failed_closure: set[str] = set();
    for fid in failed_ids {
        if fid in mp {
            w = mp[fid] spawn ClosureWalk(claimed={}, hits=set());
            for h in w.hits { failed_closure.add(h); }
        }
    }
    verdict: str = PASS;
    if receipts.__len__() == 0 {
        verdict = NOT_PROVEN;
    } else {
        if not _all_current(receipts, key) {
            verdict = NOT_PROVEN;
        } else {
            if failed_ids.__len__() > 0 {
                verdict = FAILED;
            } else {
                must = ["local_lexical", "world_currentness", "world_navigation", "world_rename", "representative", "correctness"];
                present: set[str] = set();
                for r in receipts { present.add(r.get("group", "")); }
                ok = True;
                for m in must { if not (m in present) { ok = False; } }
                if not ok {
                    verdict = NOT_PROVEN;
                } else {
                    verdict = PASS;
                }
            }
        }
    }
    # collect all node ids
    all_ids: list[str] = [];
    for k in mp { all_ids.append(k); }
    return {"candidate_key": key, "verdict": verdict, "failed_closure": sorted(list(failed_closure)), "limitations": sorted(limitations), "receipt_ids": sorted(all_ids)};
}

def claim_ceiling(packet: dict) -> str {
    if packet.get("verdict", "") != PASS { return "none"; }
    lim = packet.get("limitations", []);
    if lim.__len__() > 0 { return "static_project_limited"; }
    return "static_project";
}

def has_cross_candidate_mixing(packets: list[dict]) -> bool {
    keys: set[tuple] = set();
    for p in packets { keys.add(_binding_key(p.get("candidate", {}))); }
    return keys.__len__() > 1;
}

def is_deterministic(r1: dict, r2: dict) -> bool {
    return r1.get("candidate_key", None) == r2.get("candidate_key", None) and r1.get("verdict", None) == r2.get("verdict", None);
}

test "cutline pass with all groups" {
    candidate = {"sha": "abc", "profile_digest": "p1", "root_generation": 7, "toolchain": "1.82"};
    receipts = [
        {"id": "local_lexical", "group": "local_lexical", "candidate": candidate, "verdict": "pass", "current": True, "status": "pass", "depends_on": []},
        {"id": "world_currentness", "group": "world_currentness", "candidate": candidate, "verdict": "pass", "current": True, "status": "pass", "depends_on": ["local_lexical"]},
        {"id": "world_navigation", "group": "world_navigation", "candidate": candidate, "verdict": "pass", "current": True, "status": "pass", "depends_on": ["world_currentness"]},
        {"id": "world_rename", "group": "world_rename", "candidate": candidate, "verdict": "pass", "current": True, "status": "pass", "depends_on": ["world_navigation"]},
        {"id": "representative", "group": "representative", "candidate": candidate, "verdict": "pass", "current": True, "status": "pass", "depends_on": []},
        {"id": "correctness", "group": "correctness", "candidate": candidate, "verdict": "pass", "current": True, "status": "pass", "depends_on": ["representative"]}
    ];
    pkt = evaluate_cutline(candidate, receipts, []);
    assert pkt["verdict"] == "pass";
    assert claim_ceiling(pkt) == "static_project";
}

test "cutline not_proven on mismatched candidate" {
    candidate = {"sha": "abc", "profile_digest": "p1", "root_generation": 7, "toolchain": "1.82"};
    other = {"sha": "zzz", "profile_digest": "p1", "root_generation": 7, "toolchain": "1.82"};
    receipts = [
        {"id": "local_lexical", "group": "local_lexical", "candidate": other, "verdict": "pass", "current": True, "status": "pass", "depends_on": []}
    ];
    pkt = evaluate_cutline(candidate, receipts, []);
    assert pkt["verdict"] == "not_proven";
}

test "cutline failed propagates via walker" {
    candidate = {"sha": "abc", "profile_digest": "p1", "root_generation": 7, "toolchain": "1.82"};
    receipts = [
        {"id": "a", "group": "local_lexical", "candidate": candidate, "verdict": "failed", "current": True, "status": "pass", "depends_on": []},
        {"id": "b", "group": "world_currentness", "candidate": candidate, "verdict": "pass", "current": True, "status": "pass", "depends_on": ["a"]},
        {"id": "c", "group": "world_navigation", "candidate": candidate, "verdict": "pass", "current": True, "status": "pass", "depends_on": ["b"]}
    ];
    pkt = evaluate_cutline(candidate, receipts, []);
    assert pkt["verdict"] == "failed";
    assert "b" in pkt["failed_closure"] or "c" in pkt["failed_closure"];
}

test "claim limited" {
    pkt = {"verdict": "pass", "limitations": ["bounded"]};
    assert claim_ceiling(pkt) == "static_project_limited";
    pkt2 = {"verdict": "failed", "limitations": []};
    assert claim_ceiling(pkt2) == "none";
}

test "cross mixing symmetric" {
    c1 = {"sha": "s1", "profile_digest": "p", "root_generation": 1, "toolchain": "t"};
    c2 = {"sha": "s2", "profile_digest": "p", "root_generation": 1, "toolchain": "t"};
    assert has_cross_candidate_mixing([{"candidate": c1}, {"candidate": c2}]) == True;
    assert has_cross_candidate_mixing([{"candidate": c1}, {"candidate": c1}]) == False;
    a = evaluate_cutline(c1, [], []);
    b = evaluate_cutline(c1, [], []);
    assert is_deterministic(a, b) == True;
}
