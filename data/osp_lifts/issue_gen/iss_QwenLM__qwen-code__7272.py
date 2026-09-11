"""QwenLM/qwen-code#7272 — streaming transcript-to-display pipeline O(n) per token delta.

Each SSE text delta rebuilds the memo stage chain over the full block list.
Hand-rolled stage adjacency, deque cascade sweeps, and touch counters model the
blocks → messages → merged_messages → display_items → visible_items pipeline.
"""

from __future__ import annotations

from collections import defaultdict, deque

_STAGES = (
    "blocks",
    "messages",
    "merged_messages",
    "display_items",
    "visible_items",
)


class TranscriptPipeline:
    def __init__(self) -> None:
        self.block_rows: list[tuple[str, str, str]] = []
        self.stage_adj: dict[str, list[str]] = defaultdict(list)
        self.stage_out: dict[str, list[str]] = {}
        self.recompute_touches: int = 0


def load_transcript_pipeline(
    block_rows: list[tuple[str, str, str]],
    reference_edges: list[tuple[str, str]] | None = None,
) -> TranscriptPipeline:
    p = TranscriptPipeline()
    p.block_rows = list(block_rows)
    for i in range(len(_STAGES) - 1):
        p.stage_adj[_STAGES[i]].append(_STAGES[i + 1])
    for src, dst in reference_edges or []:
        if src in _STAGES and dst in _STAGES and dst not in p.stage_adj[src]:
            p.stage_adj[src].append(dst)
    _cascade_recompute(p, "blocks")
    return p


def _touch(p: TranscriptPipeline, stage: str, token: str) -> None:
    p.recompute_touches += 1
    _ = stage
    _ = token


def _compute_stage(p: TranscriptPipeline, stage: str) -> list[str]:
    out: list[str] = []
    if stage == "blocks":
        for bid, role, text in p.block_rows:
            _touch(p, stage, bid)
            out.append(f"{role}:{bid}:{text}")
    elif stage == "messages":
        for bid, role, _text in p.block_rows:
            _touch(p, stage, bid)
            out.append(f"msg:{role}:{bid}")
    elif stage == "merged_messages":
        prev_role = ""
        for bid, role, _text in p.block_rows:
            _touch(p, stage, bid)
            tag = role if role == prev_role else f"break:{role}"
            prev_role = role
            out.append(f"merged:{tag}:{bid}")
    elif stage == "display_items":
        for row in p.stage_out.get("merged_messages", []):
            _touch(p, stage, row)
            if "system" not in row:
                out.append(f"disp:{row}")
    elif stage == "visible_items":
        for row in p.stage_out.get("display_items", []):
            _touch(p, stage, row)
            out.append(f"vis:{row}")
    p.stage_out[stage] = out
    return out


def _cascade_recompute(p: TranscriptPipeline, origin: str) -> None:
    if origin not in _STAGES:
        return
    claimed: set[str] = set()
    work: deque[str] = deque([origin])
    while work:
        stage = work.popleft()
        if stage in claimed:
            continue
        claimed.add(stage)
        for nxt in sorted(p.stage_adj.get(stage, [])):
            if nxt not in claimed:
                work.append(nxt)
    for stage in _STAGES:
        if stage in claimed:
            _compute_stage(p, stage)


def downstream_stages(p: TranscriptPipeline, origin: str) -> list[str]:
    if origin not in p.stage_adj and origin not in _STAGES:
        return []
    claimed: set[str] = set()
    work: deque[str] = deque(sorted(p.stage_adj.get(origin, [])))
    reached: list[str] = []
    while work:
        stage = work.popleft()
        if stage in claimed:
            continue
        claimed.add(stage)
        if stage != origin:
            reached.append(stage)
        for nxt in sorted(p.stage_adj.get(stage, [])):
            if nxt not in claimed:
                work.append(nxt)
    return sorted(reached)


def apply_block_delta(p: TranscriptPipeline, block_id: str, text: str) -> None:
    hit = False
    for i, (bid, role, _old) in enumerate(p.block_rows):
        if bid == block_id:
            p.block_rows[i] = (bid, role, text)
            hit = True
            break
    if not hit:
        return
    p.recompute_touches = 0
    _cascade_recompute(p, "blocks")


def recompute_touch_count(p: TranscriptPipeline) -> int:
    return p.recompute_touches


def stage_snapshot(p: TranscriptPipeline, stage: str) -> list[str]:
    return list(p.stage_out.get(stage, []))


def visible_items(p: TranscriptPipeline) -> list[str]:
    return list(p.stage_out.get("visible_items", []))


def streaming_tail_id(p: TranscriptPipeline) -> str:
    for bid, role, _text in reversed(p.block_rows):
        if role == "assistant":
            return bid
    return ""
