"""EffortlessMetrics/perl-lsp-swarm#9473 — direct callable-result receiver transition."""

from __future__ import annotations


class CallStore:
    def __init__(self) -> None:
        self._calls: dict[str, list[str]] = {}
        self._receivers: dict[str, str | None] = {}


def load_calls(
    call_ids: list[str],
    result_alternatives: dict[str, list[str]],
) -> CallStore:
    store = CallStore()
    for cid in call_ids:
        store._calls[cid] = list(result_alternatives.get(cid, []))
        store._receivers[cid] = None
    return store


def _exact_object_alternatives(alts: list[str]) -> list[str]:
    exact: list[str] = []
    for alt in alts:
        if alt.startswith("obj:"):
            exact.append(alt[4:])
    return exact


def direct_receiver(store: CallStore, call_id: str) -> str | None:
    alts = store._calls.get(call_id, [])
    exact = _exact_object_alternatives(alts)
    if len(exact) == 1:
        return exact[0]
    return None


def receiver_outcome(store: CallStore, call_id: str) -> str:
    alts = store._calls.get(call_id, [])
    exact = _exact_object_alternatives(alts)
    if len(exact) == 1:
        return "exact"
    if len(exact) > 1:
        return "qualified"
    if any(a.startswith("obj:") for a in alts):
        return "qualified"
    if not alts:
        return "unavailable"
    return "unavailable"


def propagate_receiver(store: CallStore, call_id: str) -> str | None:
    outcome = receiver_outcome(store, call_id)
    if outcome != "exact":
        return None
    recv = direct_receiver(store, call_id)
    if recv is not None:
        store._receivers[call_id] = recv
    return recv
