"""quinnlivdahl-cmd/Nexus-App#124 — deterministic fallback for generated performance."""

from __future__ import annotations

from collections import deque
from typing import Dict, List, Optional, Set, Tuple

VALID_FAILURES = frozenset({
    "unavailable",
    "refusal",
    "malformed",
    "timeout",
    "spend_denied",
})


class CampaignStore:
    def __init__(self) -> None:
        self._truth: Dict[str, str] = {}
        self._requires: Dict[str, List[str]] = {}
        self._forward: Dict[str, List[str]] = {}
        self._generated: Dict[str, str] = {}
        self._fallback: Dict[str, str] = {}
        self._director: Dict[str, str] = {}


def load_campaign(
    beats: List[Tuple[str, str]],
    requires: List[Tuple[str, str]],
    enrichments: List[Tuple[str, str, str]],
) -> CampaignStore:
    store = CampaignStore()
    for beat_id, mechanic in beats:
        store._truth[beat_id] = mechanic
        store._requires.setdefault(beat_id, [])
        store._forward.setdefault(beat_id, [])
    for dst, src in requires:
        if dst in store._truth and src in store._truth:
            store._requires[dst].append(src)
            store._forward[src].append(dst)
    for beat_id, generated, fallback in enrichments:
        if beat_id in store._truth:
            store._generated[beat_id] = generated
            store._fallback[beat_id] = fallback
    return store


def _upstream(store: CampaignStore, beat_id: str) -> List[str]:
    if beat_id not in store._truth:
        return []
    seen: Set[str] = set()
    out: List[str] = []
    stack = [beat_id]
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        for dep in sorted(store._requires.get(cur, [])):
            if dep not in seen:
                if dep != beat_id:
                    out.append(dep)
                stack.append(dep)
    return sorted(set(out))


def _downstream(store: CampaignStore, beat_id: str) -> List[str]:
    if beat_id not in store._truth:
        return []
    seen: Set[str] = set()
    out: List[str] = []
    queue: deque[str] = deque([beat_id])
    while queue:
        cur = queue.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in sorted(store._forward.get(cur, [])):
            if nxt not in seen:
                if nxt != beat_id:
                    out.append(nxt)
                queue.append(nxt)
    return sorted(set(out))


def required_beats(store: CampaignStore, beat_id: str) -> List[str]:
    return _upstream(store, beat_id)


def downstream_beats(store: CampaignStore, beat_id: str) -> List[str]:
    return _downstream(store, beat_id)


def truth_snapshot(store: CampaignStore, beat_id: str) -> str:
    return store._truth.get(beat_id, "")


def present_enrichment(
    store: CampaignStore,
    beat_id: str,
    failure_class: Optional[str] = None,
) -> Tuple[str, str, bool]:
    if beat_id not in store._truth:
        return ("", "unknown_beat", True)
    truth_before = store._truth[beat_id]
    generated = store._generated.get(beat_id, "")
    fallback = store._fallback.get(beat_id, generated)
    used_fallback = False
    reason = "ok"
    if failure_class is not None and failure_class in VALID_FAILURES:
        presentation = fallback
        used_fallback = True
        reason = f"fallback:{failure_class}"
    elif not generated:
        presentation = fallback
        used_fallback = True
        reason = "fallback:missing_generated"
    else:
        presentation = generated
    store._director[beat_id] = presentation
    if store._truth[beat_id] != truth_before:
        store._truth[beat_id] = truth_before
    return (presentation, reason, used_fallback)


def truth_derived_path(store: CampaignStore, start: str) -> List[str]:
    if start not in store._truth:
        return []
    tokens: List[str] = [store._truth[start]]
    for bid in _downstream(store, start):
        tokens.append(store._truth[bid])
    return sorted(tokens)
