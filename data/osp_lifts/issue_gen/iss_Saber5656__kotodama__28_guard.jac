"""Guard: Saber5656/kotodama#28."""

obj KotodamaBench {
    has stages: list[str] = [];
    has preds: dict[str, list[str]] = {};
    has budgets: dict[str, int] = {};

    def load(stages: list[str], deps: list[tuple[str, str]], budgets: dict[str, int]) -> None;
    def prerequisite_closure(stage_id: str) -> list[str];
    def runnable(stages_done: set[str]) -> list[str];
    def over_budget(rss: dict[str, int]) -> list[str];
}

node Stage { has sid: str; }
edge DependsOn {}

walker AncestorWalker {
    has origin: str;
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can start with Root entry {
        for s in [-->][?:Stage] {
            if s.sid == self.origin { visit [s]; }
        }
    }

    can step with Stage entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        if here.sid != self.origin { self.found.append(here.sid); }
        visit [->:DependsOn:->];
    }
}

impl KotodamaBench.load(stages: list[str], deps: list[tuple[str, str]], budgets: dict[str, int]) -> None {
    self.stages = stages;
    self.budgets = budgets;
    self.preds = {};
    mp: dict[str, Stage] = {};
    for sid in stages {
        self.preds[sid] = [];
        if sid not in mp {
            n = Stage(sid=sid);
            root ++> n;
            mp[sid] = n;
        }
    }
    for (consumer, upstream) in deps {
        if consumer in mp and upstream in mp {
            mp[consumer] +>:DependsOn:+> mp[upstream];
            self.preds[consumer].append(upstream);
        }
    }
}

impl KotodamaBench.prerequisite_closure(stage_id: str) -> list[str] {
    if stage_id not in self.preds { return []; }
    w = root spawn AncestorWalker(origin=stage_id, claimed={}, found=[]);
    return sorted(w.found);
}

impl KotodamaBench.runnable(stages_done: set[str]) -> list[str] {
    out: list[str] = [];
    for sid in sorted(self.stages) {
        if sid in stages_done { continue; }
        ok = True;
        for pre in self.preds.get(sid, []) {
            if pre not in stages_done { ok = False; }
        }
        if ok { out.append(sid); }
    }
    return out;
}

impl KotodamaBench.over_budget(rss: dict[str, int]) -> list[str] {
    bad: list[str] = [];
    for sid in sorted(self.stages) {
        if sid in rss and sid in self.budgets and rss[sid] > self.budgets[sid] {
            bad.append(sid);
        }
    }
    return bad;
}

test "kotodama pipeline closure and gates" {
    bench = KotodamaBench();
    stages = ["capture", "asr", "format_seibun", "format_keigo"];
    deps = [
        ("asr", "capture"),
        ("format_seibun", "asr"),
        ("format_keigo", "format_seibun"),
    ];
    budgets = {"capture": 150, "asr": 500, "format_seibun": 200, "format_keigo": 200};
    bench.load(stages, deps, budgets);
    assert bench.prerequisite_closure("format_keigo") == ["asr", "capture", "format_seibun"];
    assert bench.runnable(set()) == ["capture"];
    assert bench.runnable({"capture"}) == ["asr"];
    assert bench.over_budget({"capture": 160, "asr": 400}) == ["capture"];
}

test "diamond adversarial edge order" {
    bench = KotodamaBench();
    bench.load(
        ["hub", "left", "right", "sink"],
        [("sink", "left"), ("sink", "right"), ("left", "hub"), ("right", "hub")],
        {},
    );
    assert bench.prerequisite_closure("sink") == ["hub", "left", "right"];
}

test "cycle claim-map not disengage" {
    bench = KotodamaBench();
    bench.load(
        ["a", "b", "c", "d"],
        [("a", "b"), ("b", "c"), ("c", "a"), ("d", "c")],
        {},
    );
    assert bench.prerequisite_closure("d") == ["a", "b", "c"];
}

test "unknown stage tolerance" {
    bench = KotodamaBench();
    bench.load(["only"], [], {});
    assert bench.prerequisite_closure("ghost") == [];
}
