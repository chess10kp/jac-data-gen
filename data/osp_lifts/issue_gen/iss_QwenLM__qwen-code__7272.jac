"""QwenLM/qwen-code#7272 — streaming transcript-to-display pipeline O(n) per token delta."""

glob STAGES: tuple[str, ...] = (
    "blocks",
    "messages",
    "merged_messages",
    "display_items",
    "visible_items",
);

node Stage {
    has name: str;
}

edge StageNext {}

obj TranscriptPipeline {
    has block_rows: list[tuple[str, str, str]] = [];
    has stage_out: dict[str, list[str]] = {};
    has recompute_touches: int = 0;
    has stages: dict[str, Stage] = {};
}

walker CascadeClaimWalk {
    has claimed: dict[str, bool] = {};

    can step with Stage entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        nbrs = [here ->:StageNext:->][?:Stage];
        names: list[str] = [];
        for n in nbrs { names.append(n.name); }
        for nm in sorted(names) {
            for n in nbrs {
                if n.name == nm { visit n; }
            }
        }
    }
}

walker DownstreamStagesWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Stage entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        nbrs = [here ->:StageNext:->][?:Stage];
        names: list[str] = [];
        for n in nbrs { names.append(n.name); }
        for nm in sorted(names) {
            for n in nbrs {
                if n.name == nm { visit n; }
            }
        }
    }
}

def _touch(p: TranscriptPipeline, stage: str, token: str) -> None {
    p.recompute_touches += 1;
    _ = stage;
    _ = token;
}

def _compute_stage(p: TranscriptPipeline, stage: str) -> list[str] {
    out: list[str] = [];
    if stage == "blocks" {
        for (bid, role, text) in p.block_rows {
            _touch(p, stage, bid);
            out.append(f"{role}:{bid}:{text}");
        }
    } elif stage == "messages" {
        for (bid, role, _text) in p.block_rows {
            _touch(p, stage, bid);
            out.append(f"msg:{role}:{bid}");
        }
    } elif stage == "merged_messages" {
        prev_role = "";
        for (bid, role, _text) in p.block_rows {
            _touch(p, stage, bid);
            tag = role if role == prev_role else f"break:{role}";
            prev_role = role;
            out.append(f"merged:{tag}:{bid}");
        }
    } elif stage == "display_items" {
        merged = p.stage_out.get("merged_messages", []);
        for row in merged {
            _touch(p, stage, row);
            if "system" not in row {
                out.append(f"disp:{row}");
            }
        }
    } elif stage == "visible_items" {
        disp = p.stage_out.get("display_items", []);
        for row in disp {
            _touch(p, stage, row);
            out.append(f"vis:{row}");
        }
    }
    p.stage_out[stage] = out;
    return out;
}

def _stage_of(p: TranscriptPipeline, name: str) -> Stage {
    nd = p.stages.get(name, None);
    if nd is None {
        nd = Stage(name=name);
        root ++> nd;
        p.stages[name] = nd;
    }
    return nd;
}

def _has_next(src: Stage, dst: Stage) -> bool {
    for n in [src ->:StageNext:->][?:Stage] {
        if n.name == dst.name { return True; }
    }
    return False;
}

def _cascade_recompute(p: TranscriptPipeline, origin: str) -> None {
    in_stages = False;
    for st in STAGES { if st == origin { in_stages = True; } }
    if not in_stages { return; }
    nd = p.stages.get(origin, None);
    if nd is None { return; }
    w = nd spawn CascadeClaimWalk(claimed={});
    for st in STAGES {
        if st in w.claimed { _compute_stage(p, st); }
    }
}

def load_transcript_pipeline(
    block_rows: list[tuple[str, str, str]],
    reference_edges: list[tuple[str, str]] | None = None,
) -> TranscriptPipeline {
    p = TranscriptPipeline();
    p.block_rows = [];
    for row in block_rows { p.block_rows.append(row); }
    for i in range(len(STAGES) - 1) {
        src = _stage_of(p, STAGES[i]);
        dst = _stage_of(p, STAGES[i + 1]);
        if not _has_next(src, dst) { src +>:StageNext:+> dst; }
    }
    for (src_name, dst_name) in reference_edges or [] {
        in_src = False;
        in_dst = False;
        for st in STAGES {
            if st == src_name { in_src = True; }
            if st == dst_name { in_dst = True; }
        }
        if in_src and in_dst {
            src_nd = _stage_of(p, src_name);
            dst_nd = _stage_of(p, dst_name);
            if not _has_next(src_nd, dst_nd) { src_nd +>:StageNext:+> dst_nd; }
        }
    }
    _cascade_recompute(p, "blocks");
    return p;
}

def downstream_stages(p: TranscriptPipeline, origin: str) -> list[str] {
    in_stages = False;
    for st in STAGES { if st == origin { in_stages = True; } }
    has_adj = origin in p.stages;
    if not has_adj and not in_stages { return []; }
    nd = p.stages.get(origin, None);
    if nd is None { return []; }
    children = [nd ->:StageNext:->][?:Stage];
    claimed: dict[str, bool] = {};
    reached: list[str] = [];
    names: list[str] = [];
    for ch in children { names.append(ch.name); }
    for nm in sorted(names) {
        for ch in children {
            if ch.name == nm {
                w = ch spawn DownstreamStagesWalk(claimed=claimed, reached=reached);
                claimed = w.claimed;
                reached = w.reached;
            }
        }
    }
    filtered: list[str] = [];
    for r in reached { if r != origin { filtered.append(r); } }
    return sorted(filtered);
}

def apply_block_delta(p: TranscriptPipeline, block_id: str, text: str) -> None {
    hit = False;
    for i in range(len(p.block_rows)) {
        (bid, role, _old) = p.block_rows[i];
        if bid == block_id {
            p.block_rows[i] = (bid, role, text);
            hit = True;
            break;
        }
    }
    if not hit { return; }
    p.recompute_touches = 0;
    _cascade_recompute(p, "blocks");
}

def recompute_touch_count(p: TranscriptPipeline) -> int {
    return p.recompute_touches;
}

def stage_snapshot(p: TranscriptPipeline, stage: str) -> list[str] {
    rows = p.stage_out.get(stage, []);
    out: list[str] = [];
    for row in rows { out.append(row); }
    return out;
}

def visible_items(p: TranscriptPipeline) -> list[str] {
    rows = p.stage_out.get("visible_items", []);
    out: list[str] = [];
    for row in rows { out.append(row); }
    return out;
}

def streaming_tail_id(p: TranscriptPipeline) -> str {
    for i in range(len(p.block_rows) - 1, -1, -1) {
        (bid, role, _text) = p.block_rows[i];
        if role == "assistant" { return bid; }
    }
    return "";
}
