"""crzyc98/planwise_navigator#589 — dbt mart pipeline orphan audit.

The orphaned fct_policy_optimization mart depends on demo variables and sits
outside the production build selection. Hand-rolled dependency adjacency,
reverse referencer index, and deque reach walks over the workflow DAG.
"""

from __future__ import annotations

from collections import deque


class MartDag:
  def __init__(self) -> None:
        self._models: set[str] = set()
        self._kinds: dict[str, str] = {}
        self._tags: dict[str, set[str]] = {}
        self._deps: dict[str, list[str]] = {}   # model -> upstream models
        self._refs: dict[str, list[str]] = {}   # upstream -> downstream models


def load_mart_dag(
    models: list[tuple[str, str, list[str]]],
    dependencies: list[tuple[str, str]],
) -> MartDag:
    dag = MartDag()
    for name, kind, tags in models:
        dag._models.add(name)
        dag._kinds[name] = kind
        dag._tags[name] = set(tags)
        dag._deps.setdefault(name, [])
        dag._refs.setdefault(name, [])
    for model, upstream in dependencies:
        if model in dag._models and upstream in dag._models:
            dag._deps[model].append(upstream)
            dag._refs[upstream].append(model)
    return dag


def _reach(dag: MartDag, start: str, adj: dict[str, list[str]]) -> list[str]:
    if start not in dag._models:
        return []
    seen: set[str] = set()
    queue: deque[str] = deque([start])
    while queue:
        cur = queue.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in sorted(adj.get(cur, [])):
            if nxt not in seen:
                queue.append(nxt)
    seen.discard(start)
    return sorted(seen)


def upstream_reach(dag: MartDag, model: str) -> list[str]:
    return _reach(dag, model, dag._deps)


def downstream_reach(dag: MartDag, model: str) -> list[str]:
    return _reach(dag, model, dag._refs)


def direct_referencers(dag: MartDag, target: str) -> list[str]:
    if target not in dag._models:
        return []
    return sorted(dag._refs.get(target, []))


def production_closure(dag: MartDag, selection_roots: list[str]) -> list[str]:
    included: set[str] = set()
    for root in selection_roots:
        if root not in dag._models:
            continue
        included.add(root)
        included.update(upstream_reach(dag, root))
    return sorted(included)


def orphan_facts(dag: MartDag, selection_roots: list[str]) -> list[str]:
    live = set(production_closure(dag, selection_roots))
    return sorted(
        name
        for name in dag._models
        if dag._kinds.get(name) == "fact" and name not in live
    )
