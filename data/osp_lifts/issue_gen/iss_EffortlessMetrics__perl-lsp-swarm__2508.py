"""EffortlessMetrics/perl-lsp-swarm#2508 — incremental per-file semantic facts."""

from __future__ import annotations

from collections import deque


class SemanticGraph:
  def __init__(self) -> None:
    self._scopes: set[str] = set()
    self._parent: dict[str, str | None] = {}
    self._depends: dict[str, list[str]] = {}
    self._facts: dict[str, str] = {}
    self._anchors: dict[str, int] = {}


def load_semantic_graph(
  scopes: list[str],
  parent_of: list[tuple[str, str | None]],
  depends: list[tuple[str, str]],
  facts: dict[str, str],
  anchors: dict[str, int],
) -> SemanticGraph:
  g = SemanticGraph()
  for sid in scopes:
    g._scopes.add(sid)
    g._parent.setdefault(sid, None)
    g._depends.setdefault(sid, [])
  for child, parent in parent_of:
    if child in g._scopes:
      g._parent[child] = parent
  for consumer, producer in depends:
    if consumer in g._scopes and producer in g._scopes:
      g._depends.setdefault(consumer, []).append(producer)
  for sid, val in facts.items():
    if sid in g._scopes:
      g._facts[sid] = val
  for sid, pos in anchors.items():
    if sid in g._scopes:
      g._anchors[sid] = pos
  return g


def enclosing_scope_chain(g: SemanticGraph, scope: str) -> list[str]:
  if scope not in g._scopes:
    return []
  chain = [scope]
  claimed = {scope}
  cur = scope
  while True:
    par = g._parent.get(cur)
    if par is None or par in claimed:
      break
    claimed.add(par)
    chain.append(par)
    cur = par
  return chain


def dependent_contributions(g: SemanticGraph, seeds: list[str]) -> list[str]:
  rev: dict[str, list[str]] = {s: [] for s in g._scopes}
  for consumer, ups in g._depends.items():
    for up in ups:
      rev[up].append(consumer)
  orig_seeds = {s for s in seeds if s in g._scopes}
  seen: set[str] = set()
  q: deque[str] = deque()
  for seed in seeds:
    if seed in g._scopes:
      seen.add(seed)
      q.append(seed)
  while q:
    cur = q.popleft()
    for nxt in sorted(rev.get(cur, [])):
      if nxt not in seen:
        # nested token: if nxt's parent is cur, only traverse if cur is original seed
        if g._parent.get(nxt) == cur and cur not in orig_seeds:
          continue
        seen.add(nxt)
        q.append(nxt)
  return sorted(seen)


def refresh_facts(
  g: SemanticGraph,
  seeds: list[str],
  impact: str,
  shift: int = 0,
  recomputed: dict[str, str] | None = None,
) -> tuple[str, dict[str, str], dict[str, int]]:
  facts = dict(g._facts)
  anchors = dict(g._anchors)
  if impact == "no_change":
    return ("retain", facts, anchors)
  if impact == "topology":
    return ("fallback", dict(recomputed or {}), anchors)
  if impact == "range_shift":
    for sid in seeds:
      if sid in anchors:
        anchors[sid] += shift
    return ("rebase", facts, anchors)
  affected = set(dependent_contributions(g, seeds))
  kept: dict[str, str] = {}
  payload = recomputed or {}
  for sid, val in facts.items():
    if sid not in affected:
      kept[sid] = val
  for sid in sorted(affected):
    if sid in payload:
      kept[sid] = payload[sid]
    elif sid in facts:
      kept[sid] = facts[sid]
  return ("recompute", kept, anchors)
