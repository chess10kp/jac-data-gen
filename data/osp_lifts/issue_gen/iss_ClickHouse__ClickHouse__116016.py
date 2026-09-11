"""ClickHouse/ClickHouse#116016 — recursive CTE depth guard with sibling self-join."""

from __future__ import annotations

from collections import deque


class TooDeepRecursion(Exception):
  def __init__(self, cte: str, depth: int) -> None:
    self.cte = cte
    self.depth = depth
    super().__init__(f"TOO_DEEP_RECURSION: {cte} depth={depth}")


class CtePlan:
  def __init__(self, max_depth: int) -> None:
    self.max_depth = max_depth
    self._deps: dict[str, list[str]] = {}
    self._spec: dict[str, tuple[str, ...]] = {}


def make_plan(max_depth: int = 5) -> CtePlan:
  return CtePlan(max_depth)


def add_linear_cte(plan: CtePlan, name: str, lo: int, hi: int) -> None:
  plan._spec[name] = ("linear", str(lo), str(hi))
  plan._deps[name] = []


def add_projection_cte(plan: CtePlan, name: str, source: str) -> None:
  plan._spec[name] = ("projection", source)
  plan._deps[name] = [source]


def add_self_join_cte(
  plan: CtePlan, name: str, base: str, join_source: str
) -> None:
  plan._spec[name] = ("self_join", base, join_source)
  plan._deps[name] = sorted({base, join_source})


def dependency_closure(plan: CtePlan, target: str) -> list[str]:
  if target not in plan._spec:
    return []
  needed: set[str] = set()
  stack: list[str] = [target]
  while stack:
    cur = stack.pop()
    if cur in needed:
      continue
    needed.add(cur)
    for dep in plan._deps.get(cur, []):
      if dep not in needed:
        stack.append(dep)
  indeg: dict[str, int] = {n: 0 for n in needed}
  for node in needed:
    for dep in plan._deps.get(node, []):
      if dep in needed:
        indeg[node] += 1
  ready: deque[str] = deque(sorted(n for n in needed if indeg[n] == 0))
  order: list[str] = []
  while ready:
    node = ready.popleft()
    order.append(node)
    for other in sorted(needed):
      if node in plan._deps.get(other, []):
        indeg[other] -= 1
        if indeg[other] == 0:
          ready.append(other)
  return order


def _eval_linear(plan: CtePlan, lo: int, hi: int) -> list[int]:
  rows = [lo]
  depth = 0
  while rows[-1] < hi:
    depth += 1
    if depth > plan.max_depth:
      raise TooDeepRecursion("linear", depth)
    rows.append(rows[-1] + 1)
  return rows


def _eval_projection(cache: dict[str, list[int]], source: str) -> list[int]:
  return list(cache[source])


def _eval_self_join(
  plan: CtePlan, name: str, cache: dict[str, list[int]]
) -> list[int]:
  base, join_src = plan._spec[name][1], plan._spec[name][2]
  join_set = set(cache[join_src])
  acc = list(cache[base])
  depth = 0
  while True:
    depth += 1
    if depth > plan.max_depth:
      raise TooDeepRecursion(name, depth)
    additions: list[int] = []
    for row in acc:
      additions.append(row)
      if row in join_set:
        additions.append(row)
    if not additions:
      break
    acc.extend(additions)
  return acc


def _materialize(plan: CtePlan, name: str) -> list[int]:
  cache: dict[str, list[int]] = {}
  for cte in dependency_closure(plan, name):
    kind = plan._spec[cte][0]
    if kind == "linear":
      cache[cte] = _eval_linear(plan, int(plan._spec[cte][1]), int(plan._spec[cte][2]))
    elif kind == "projection":
      cache[cte] = _eval_projection(cache, plan._spec[cte][1])
    else:
      cache[cte] = _eval_self_join(plan, cte, cache)
  return cache[name]


def materialize_cte(plan: CtePlan, name: str) -> list[int]:
  if name not in plan._spec:
    return []
  return sorted(_materialize(plan, name))


def build_issue_fixture(max_depth: int = 5) -> CtePlan:
  plan = make_plan(max_depth)
  add_linear_cte(plan, "sq1", 1, 5)
  add_projection_cte(plan, "sq2", "sq1")
  add_self_join_cte(plan, "sq3", "sq2", "sq2")
  return plan
