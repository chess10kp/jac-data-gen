"""gastownhall/gascity#5383 — Reaper workflow query layers."""

class CycleError(ValueError) {}

node ReapStep { has step_id: str; }
edge Depends {}

obj ReaperGraph {
    def add_step(step_id: str) -> None { root ++> ReapStep(step_id=step_id); }
    def add_depends(step_id: str, depends_on: str) -> None {
        s = self._find(step_id); d = self._find(depends_on);
        if s is None or d is None { raise KeyError("unknown step"); }
        d +>:Depends:+> s;
    }
    def query_layers() -> list[list[str]] {
        w = root spawn LayerPlanner();
        if w.error { raise CycleError("cycle blocks layering"); }
        return w.layers;
    }
    def reachable_downstream(start: str) -> list[str] {
        n = self._find(start);
        if n is None { return []; }
        w = root spawn Downstream();
        n spawn DownstreamWalker(walker=w);
        return sorted(w.seen);
    }
    def _find(step_id: str) -> ReapStep | None {
        for s in [root-->[?:ReapStep]] { if s.step_id == step_id { return s; } }
        return None;
    }
}

walker LayerPlanner {
    has layers: list[list[str]] = [];
    has error: bool = False;
    can plan with Root entry {
        indeg: dict[str, int] = {};
        rev: dict[str, list[str]] = {};
        ids: list[str] = [];
        for s in [-->][?:ReapStep] {
            ids.append(s.step_id);
            indeg[s.step_id] = len([s<--][?:ReapStep]);
            rev[s.step_id] = [x.step_id for x in [s-->[?:ReapStep]]];
        }
        seen: dict[str, bool] = {};
        frontier = sorted([i for i in ids if indeg[i] == 0]);
        while len(frontier) > 0 {
            layer = sorted(frontier);
            self.layers.append(layer);
            nxt: list[str] = [];
            for u in layer {
                seen[u] = True;
                for v in sorted(rev.get(u, [])) {
                    indeg[v] -= 1;
                    if indeg[v] == 0 and v not in seen { nxt.append(v); }
                }
            }
            frontier = nxt;
        }
        if len(seen) != len(ids) { self.error = True; }
    }
}

walker Downstream { has seen: list[str] = []; has claimed: dict[str, bool] = {}; }
walker DownstreamWalker(Downstream) {
    can step with ReapStep entry {
        if here.step_id in self.claimed { skip; }
        self.claimed[here.step_id] = True;
        self.seen.append(here.step_id);
        visit [here-->[?:ReapStep]];
    }
}

def build_reaper() -> ReaperGraph { return ReaperGraph(); }
