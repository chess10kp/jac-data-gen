"""cskwork/math-item-os#15 — Prerequisite DAG traversal (recursive CTE prototype).

Hand-rolled parent/child adjacency, deque BFS, and frontier-stack walks
simulating recursive CTE ancestor/descendant queries with per-skill item counts.
"""
from __future__ import annotations

from collections import deque


class Skill:
    def __init__(self, skill_id: str, item_count: int = 0) -> None:
        self.skill_id = skill_id
        self.item_count = item_count


class PrerequisiteGraph:
    def __init__(self) -> None:
        self.skills: dict[str, bool] = {}
        self.item_counts: dict[str, int] = {}
        self.skill_nodes: dict[str, Skill] = {}
        self._requires: dict[str, list[str]] = {}
        self._required_by: dict[str, list[str]] = {}


def load_prerequisite_graph(
    skills: list[tuple[str, int]],
    prerequisites: list[tuple[str, str]],
) -> PrerequisiteGraph:
    g = PrerequisiteGraph()
    for skill_id, count in skills:
        g.skills[skill_id] = True
        g.item_counts[skill_id] = count
        g.skill_nodes[skill_id] = Skill(skill_id=skill_id, item_count=count)
        g._requires[skill_id] = []
        g._required_by[skill_id] = []
    for dependent, prereq in prerequisites:
        if dependent in g.skills and prereq in g.skills:
            g._requires[dependent].append(prereq)
            g._required_by[prereq].append(dependent)
    for sid in g.skills:
        g._requires[sid] = sorted(g._requires[sid])
        g._required_by[sid] = sorted(g._required_by[sid])
    return g


def _ancestor_walk(g: PrerequisiteGraph, origin: str, max_depth: int) -> list[str]:
    found: list[str] = []
    claimed: dict[str, bool] = {}

    def step(sid: str, depth: int) -> None:
        if sid in claimed:
            return
        if sid != origin or depth > 0:
            claimed[sid] = True
            found.append(sid)
        if depth >= max_depth:
            return
        for nm in g._requires.get(sid, []):
            step(nm, depth + 1)

    step(origin, 0)
    return found


def _descendant_walk(g: PrerequisiteGraph, origin: str, max_depth: int) -> list[str]:
    reached: list[str] = []
    claimed: dict[str, bool] = {}
    q: deque[tuple[str, int]] = deque([(origin, 0)])
    while q:
        sid, depth = q.popleft()
        if sid in claimed:
            continue
        claimed[sid] = True
        if sid != origin:
            reached.append(sid)
        if depth >= max_depth:
            continue
        for nm in g._required_by.get(sid, []):
            if nm not in claimed:
                q.append((nm, depth + 1))
    return reached


def get_ancestors(
    g: PrerequisiteGraph,
    skill_id: str,
    *,
    max_depth: int = 16,
) -> list[str]:
    if skill_id not in g.skills or max_depth <= 0:
        return []
    if g.skill_nodes.get(skill_id, None) is None:
        return []
    return sorted(_ancestor_walk(g, skill_id, max_depth))


def get_descendants(
    g: PrerequisiteGraph,
    skill_id: str,
    *,
    max_depth: int = 16,
) -> list[str]:
    if skill_id not in g.skills or max_depth <= 0:
        return []
    if g.skill_nodes.get(skill_id, None) is None:
        return []
    return sorted(_descendant_walk(g, skill_id, max_depth))


def aggregate_item_counts(
    g: PrerequisiteGraph,
    skill_id: str,
    direction: str = "descendants",
) -> list[tuple[str, int]]:
    if skill_id not in g.skills:
        return []
    reach: list[str] = []
    if direction == "ancestors":
        reach = get_ancestors(g, skill_id)
    elif direction == "descendants":
        reach = get_descendants(g, skill_id)
    else:
        return []
    out: list[tuple[str, int]] = []
    for sid in reach:
        out.append((sid, g.item_counts[sid]))
    return sorted(out)
