"""jordan-thirkle/ai-game-development-pipeline#305 — BYJTT-LAB-001 integrated Three.js alpha browser perf pipeline DAG."""

node Stage {
    has stage_id: str;
}

edge Depends {}

obj PipelineGraph {
    has _root: Root;

    def init() {
        self._root = root;
    }

    def add_stage(stage_id: str) -> None {
        if self._find(stage_id) is not None {
            return;
        }
        self._root ++> Stage(stage_id=stage_id);
    }

    def add_dependency(stage: str, depends_on: str) -> None {
        tgt = self._find(stage);
        pred = self._find(depends_on);
        if tgt is None or pred is None {
            raise KeyError("unknown pipeline stage id");
        }
        pred +>:Depends:+> tgt;
    }

    def find_cycle() -> list[str] {
        w = self._root spawn CycleFinder();
        if w.cycle {
            return w.cycle;
        }
        return [];
    }

    def downstream(stage: str) -> list[str] {
        n = self._find(stage);
        if n is None {
            return [];
        }
        w = n spawn DownstreamWalker(start_id=stage);
        return sorted(w.hits);
    }

    def _find(stage_id: str) -> Stage | None {
        for t in [self._root-->[?:Stage]] {
            if t.stage_id == stage_id {
                return t;
            }
        }
        return None;
    }
}

walker CycleFinder {
    has cycle: list[str] = [];
    has on_stack: dict[str, bool] = {};
    has stack_ids: list[str] = [];

    can start with Root entry {
        visit [-->][?:Stage];
    }

    can walk with Stage entry {
        if self.cycle {
            skip;
        }
        sid = here.stage_id;
        if sid in self.on_stack and self.on_stack[sid] {
            i = 0;
            for (idx, x) in enumerate(self.stack_ids) {
                if x == sid {
                    i = idx;
                    break;
                }
            }
            self.cycle = self.stack_ids[i:] + [sid];
            skip;
        }
        self.on_stack[sid] = True;
        self.stack_ids = self.stack_ids + [sid];
        visit [-->][?:Stage];
        self.stack_ids = self.stack_ids[:-1];
        self.on_stack[sid] = False;
    }
}

walker DownstreamWalker {
    has start_id: str;
    has claims: dict[str, bool] = {};
    has hits: list[str] = [];

    can walk with Stage entry {
        sid = here.stage_id;
        if sid in self.claims {
            skip;
        }
        self.claims[sid] = True;
        if sid != self.start_id {
            self.hits.append(sid);
        }
        visit [here-->[?:Stage]];
    }
}
