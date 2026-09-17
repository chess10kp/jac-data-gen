# vesmaro/vesmaro#325 — layered BFS-2 with rank-only feedback apply
# fanout cap, total-work cap, first-anchor-wins path attribution,
# graph_epoch cache key. Gate: edges/100 >= 50.

node Memory {
    has mid: str;
    has conf: float = 1.0;
}

edge Link {
    has weight: float = 1.0;
}

obj Engine {
    has idx: dict[str, Memory];
    has epoch: int = 0;
    has alpha: float = 0.5;
    has rrf_k: float = 60.0;
    has fanout: int = 3;
    has max_visit: int = 20;

    def gate_ok(total_edges: int, records: int) -> bool {
        if records == 0 { return False; }
        return (total_edges * 100) / records >= 50.0;
    }

    def bfs2(start: str) -> dict[str, float] {
        # layered BFS-2: 2 levels x 2 directions, capped
        scores: dict[str, float] = {};
        frontier: list[Memory] = [];
        src: Memory | None = self.idx.get(start);
        if src is None { return scores; }
        frontier.append(src);
        visited: dict[str, bool] = {};
        visited[start] = True;
        depth: int = 0;
        budget: int = self.max_visit;
        while len(frontier) > 0 and depth < 2 {
            nxt: list[Memory] = [];
            for nd in frontier {
                kids: list[Memory] = [nd ->:Link:->][?:Memory];
                cap: int = self.fanout;
                k: int = 0;
                for ch in kids {
                    if k >= cap or budget <= 0 { break; }
                    k += 1;
                    budget -= 1;
                    if ch.mid in visited { continue; }
                    visited[ch.mid] = True;
                    cont: float = (1.0 - self.alpha) / (self.rrf_k + 2.0 * float(depth));
                    rank: float = cont * 0.7 ** depth;
                    scores[ch.mid] = rank;
                    nxt.append(ch);
                }
            }
            frontier = nxt;
            depth += 1;
        }
        return scores;
    }

    def apply_feedback(mid: str, factor: float, delta_cap: float) -> int {
        # rank-only bounded-delta feedback apply; unknown id -> -1
        tgt: Memory | None = self.idx.get(mid);
        if tgt is None { return -1; }
        if factor > delta_cap { factor = delta_cap; }
        tgt.conf = tgt.conf * (1.0 + factor);
        return 1;
    }

    def cache_key() -> str {
        return "assemble_context:v1:epoch=" + str(self.epoch);
    }
}

def bump_epoch(eng: Engine) -> int {
    eng.epoch += 1;
    return eng.epoch;
}

walker Assemble {
    has start: str;
    has found: dict[str, float] = {};
    has key: str = "";

    can step with Engine entry {
        self.found = here.bfs2(self.start);
        self.key = here.cache_key();
        print("bfs2", self.start, sorted(self.found.keys()), self.key);
        disengage;
    }
}

with entry {
    eng = Engine(idx={});
    a = Memory(mid="m1");
    b = Memory(mid="m2");
    c = Memory(mid="m3");
    d = Memory(mid="m4");
    eng.idx["m1"] = a;
    eng.idx["m2"] = b;
    eng.idx["m3"] = c;
    eng.idx["m4"] = d;
    root ++> a;
    a +>:Link:+> b;
    a +>:Link:+> c;
    b +>:Link:+> d;
    c +>:Link:+> d;
    bump_epoch(eng);
    w = eng spawn Assemble(start="m1", found={}, key="");
}

test "gate" {
    eng = Engine(idx={});
    assert eng.gate_ok(50, 100) == True;
    assert eng.gate_ok(49, 100) == False;
    assert eng.gate_ok(10, 0) == False;
}

test "bfs2_levels" {
    eng = Engine(idx={});
    a = Memory(mid="m1");
    b = Memory(mid="m2");
    c = Memory(mid="m3");
    d = Memory(mid="m4");
    eng.idx["m1"] = a;
    eng.idx["m2"] = b;
    eng.idx["m3"] = c;
    eng.idx["m4"] = d;
    a +>:Link:+> b;
    a +>:Link:+> c;
    b +>:Link:+> d;
    c +>:Link:+> d;
    sc = eng.bfs2("m1");
    keys = sorted(sc.keys());
    assert keys == ["m2", "m3", "m4"];
    assert sc["m2"] > sc["m4"];
    assert eng.bfs2("nope") == {};
}

test "fanout_cap" {
    eng = Engine(idx={});
    a = Memory(mid="m1");
    eng.idx["m1"] = a;
    for i in range(6) {
        kid = Memory(mid="k" + str(i));
        eng.idx["k" + str(i)] = kid;
        a +>:Link:+> kid;
    }
    sc = eng.bfs2("m1");
    assert len(sc.keys()) == 3;
}

test "feedback_unknown_and_cap" {
    eng = Engine(idx={});
    m = Memory(mid="m1");
    eng.idx["m1"] = m;
    assert eng.apply_feedback("zz", 0.5, 0.2) == -1;
    assert eng.apply_feedback("m1", 0.9, 0.2) == 1;
    assert abs(m.conf - 1.2) < 1e-9;
    assert eng.apply_feedback("m1", 0.1, 0.2) == 1;
    assert abs(m.conf - 1.2 * 1.1) < 1e-9;
}

test "epoch_cache_key" {
    eng = Engine(idx={});
    assert eng.cache_key() == "assemble_context:v1:epoch=0";
    assert bump_epoch(eng) == 1;
    assert eng.cache_key() == "assemble_context:v1:epoch=1";
    assert bump_epoch(eng) == 2;
    assert eng.cache_key() == "assemble_context:v1:epoch=2";
}

test "walker_assemble" {
    eng = Engine(idx={});
    a = Memory(mid="m1");
    b = Memory(mid="m2");
    eng.idx["m1"] = a;
    eng.idx["m2"] = b;
    a +>:Link:+> b;
    bump_epoch(eng);
    w = eng spawn Assemble(start="m1", found={}, key="");
    assert sorted(w.found.keys()) == ["m2"];
    assert w.key == "assemble_context:v1:epoch=1";
}
