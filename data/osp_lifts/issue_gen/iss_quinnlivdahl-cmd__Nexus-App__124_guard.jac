"""Guard tests for iss_quinnlivdahl-cmd__Nexus-App__124.jac"""

obj CampaignStore { has stamp: int = 0; }
node Beat {
    has beat_id: str;
    has mechanic: str;
    has generated: str = "";
    has fallback: str = "";
    has director_text: str = "";
}
edge Requires {}

walker UpstreamWalk {
    has start: str;
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    can begin with Root entry {
        for b in [-->][?:Beat] { if b.beat_id == self.start { visit [b]; } }
    }
    can step with Beat entry {
        if here.beat_id in self.claimed { skip; }
        self.claimed[here.beat_id] = True;
        for dep in [here->:Requires:->][?:Beat] {
            if dep.beat_id != self.start { self.reached.append(dep.beat_id); }
            visit [dep];
        }
    }
    can finish with Root exit { report self.reached; }
}

walker DownstreamWalk {
    has start: str;
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    can begin with Root entry {
        for b in [-->][?:Beat] { if b.beat_id == self.start { visit [b]; } }
    }
    can step with Beat entry {
        if here.beat_id in self.claimed { skip; }
        self.claimed[here.beat_id] = True;
        if here.beat_id != self.start { self.reached.append(here.beat_id); }
        visit [here <-:Requires:<-][?:Beat];
    }
    can finish with Root exit { report self.reached; }
}

glob VALID_FAILURES = ["unavailable", "refusal", "malformed", "timeout", "spend_denied"];

def _wire(
    beats: list[tuple[str, str]],
    requires: list[tuple[str, str]],
    enrichments: list[tuple[str, str, str]],
) {
    mp: dict[str, Beat] = {};
    for (bid, mech) in beats {
        if bid not in mp { b = Beat(beat_id=bid, mechanic=mech); root ++> b; mp[bid] = b; }
    }
    for (dst, src) in requires {
        d = mp.get(dst, None); s = mp.get(src, None);
        if d is not None and s is not None { d +>:Requires:+> s; }
    }
    for (bid, gen, fb) in enrichments {
        bx = mp.get(bid, None);
        if bx is not None { bx.generated = gen; bx.fallback = fb; }
    }
}

def _beat(bid: str) -> Beat | None {
    for b in [-->][?:Beat] { if b.beat_id == bid { return b; } }
    return None;
}

def _is_valid_failure(fc: str | None) -> bool {
    if fc is None { return False; }
    for v in VALID_FAILURES { if v == fc { return True; } }
    return False;
}

def load_campaign(
    beats: list[tuple[str, str]],
    requires: list[tuple[str, str]],
    enrichments: list[tuple[str, str, str]],
) -> CampaignStore {
    _wire(beats, requires, enrichments);
    return CampaignStore(stamp=1);
}

def required_beats(store: CampaignStore, beat_id: str) -> list[str] {
    _ = store;
    if _beat(beat_id) is None { return []; }
    w = root spawn UpstreamWalk(start=beat_id, claimed={}, reached=[]);
    return sorted(w.reports[0] if w.reports else []);
}

def downstream_beats(store: CampaignStore, beat_id: str) -> list[str] {
    _ = store;
    if _beat(beat_id) is None { return []; }
    w = root spawn DownstreamWalk(start=beat_id, claimed={}, reached=[]);
    return sorted(w.reports[0] if w.reports else []);
}

def truth_snapshot(store: CampaignStore, beat_id: str) -> str {
    _ = store;
    b = _beat(beat_id);
    if b is None { return ""; }
    return b.mechanic;
}

def present_enrichment(
    store: CampaignStore,
    beat_id: str,
    failure_class: str | None = None,
) -> tuple[str, str, bool] {
    _ = store;
    b = _beat(beat_id);
    if b is None { return ("", "unknown_beat", True); }
    truth_before = b.mechanic;
    used_fallback = False;
    reason = "ok";
    if _is_valid_failure(failure_class) {
        b.director_text = b.fallback;
        used_fallback = True;
        reason = f"fallback:{failure_class}";
    } else {
        if b.generated == "" {
            b.director_text = b.fallback;
            used_fallback = True;
            reason = "fallback:missing_generated";
        } else {
            b.director_text = b.generated;
        }
    }
    if b.mechanic != truth_before { b.mechanic = truth_before; }
    return (b.director_text, reason, used_fallback);
}

def truth_derived_path(store: CampaignStore, start: str) -> list[str] {
    _ = store;
    ids = downstream_beats(store, start);
    out: list[str] = [];
    sb = _beat(start);
    if sb is not None { out.append(sb.mechanic); }
    for bid in ids {
        bx = _beat(bid);
        if bx is not None { out.append(bx.mechanic); }
    }
    return sorted(out);
}

test "campaign path and truth-preserving fallback" {
    store = load_campaign(
        [("intro", "M:intro_ok"), ("route2", "M:route2_ok"), ("finale", "M:finale_ok")],
        [("route2", "intro"), ("finale", "route2")],
        [
            ("intro", "Narr: intro bloom", "FB: intro steady"),
            ("route2", "Narr: route pulse", "FB: route steady"),
            ("finale", "Narr: finale crest", "FB: finale steady"),
        ],
    );
    assert required_beats(store, "finale") == ["intro", "route2"];
    assert downstream_beats(store, "intro") == ["finale", "route2"];
    assert truth_snapshot(store, "finale") == "M:finale_ok";
    (pres, reason, fb) = present_enrichment(store, "finale", "timeout");
    assert pres == "FB: finale steady";
    assert reason == "fallback:timeout";
    assert fb is True;
    assert truth_snapshot(store, "finale") == "M:finale_ok";
    (ok_pres, ok_reason, ok_fb) = present_enrichment(store, "intro", None);
    assert ok_pres == "Narr: intro bloom";
    assert ok_reason == "ok";
    assert ok_fb is False;
    assert truth_derived_path(store, "intro") == [
        "M:finale_ok", "M:intro_ok", "M:route2_ok",
    ];
}

test "all failure classes preserve truth" {
    store = load_campaign(
        [("beat", "M:stable")],
        [],
        [("beat", "Narr: live", "FB: safe")],
    );
    for fc in VALID_FAILURES {
        (p, r, used) = present_enrichment(store, "beat", fc);
        assert p == "FB: safe";
        assert r == f"fallback:{fc}";
        assert used is True;
        assert truth_snapshot(store, "beat") == "M:stable";
    }
}

test "diamond adversarial upstream" {
    store = load_campaign(
        ["top", "left", "right", "base", "leaf"],
        [
            ("top", "right"),
            ("base", "leaf"),
            ("top", "left"),
            ("right", "base"),
            ("left", "base"),
        ],
        [("top", "gen", "fb")],
    );
    assert required_beats(store, "top") == ["base", "leaf", "left", "right"];
}

test "diamond adversarial downstream" {
    store = load_campaign(
        ["leaf", "base", "left", "right", "top"],
        [
            ("base", "leaf"),
            ("left", "base"),
            ("right", "base"),
            ("top", "left"),
            ("top", "right"),
        ],
        [],
    );
    assert downstream_beats(store, "leaf") == ["base", "left", "right", "top"];
}

test "unknown beat tolerant" {
    store = load_campaign([("only", "M:x")], [], []);
    assert required_beats(store, "missing") == [];
    assert downstream_beats(store, "missing") == [];
    assert truth_snapshot(store, "missing") == "";
    assert truth_derived_path(store, "missing") == [];
    (p, r, fb) = present_enrichment(store, "missing", "timeout");
    assert p == "";
    assert r == "unknown_beat";
    assert fb is True;
}
