"""Deen-Bridge/dnb-ai#155 — Intelligent agent task decomposition dependency planner.

Query decomposition builds sub-task DAGs with prerequisite edges, BFS downstream
closure over dependents adjacency, Kahn wave scheduling for parallel batches, and
greedy agent matching by capability tags.
"""

from __future__ import annotations

from collections import deque


class DecompStore:
    def __init__(self) -> None:
        self.tasks: set[str] = set()
        self.prereqs: dict[str, list[str]] = {}
        self.dependents: dict[str, list[str]] = {}
        self.required_skill: dict[str, str] = {}
        self.agent_skills: dict[str, set[str]] = {}


def load_decomposition_store(
    task_ids: list[str],
    depends: list[tuple[str, str]],
    skills: dict[str, str] | None = None,
    agents: dict[str, list[str]] | None = None,
) -> DecompStore:
    store = DecompStore()
    for tid in task_ids:
        store.tasks.add(tid)
        store.prereqs[tid] = []
        store.dependents[tid] = []
    for blocker, dependent in depends:
        if blocker in store.tasks and dependent in store.tasks:
            store.prereqs[dependent].append(blocker)
            store.dependents[blocker].append(dependent)
    for tid in store.prereqs:
        store.prereqs[tid].sort()
    for tid in store.dependents:
        store.dependents[tid].sort()
    for tid, skill in (skills or {}).items():
        if tid in store.tasks:
            store.required_skill[tid] = skill
    for agent, caps in (agents or {}).items():
        store.agent_skills[agent] = set(caps)
    return store


def downstream_closure(store: DecompStore, task_id: str) -> list[str]:
    if task_id not in store.tasks:
        return []
    claimed: set[str] = {task_id}
    hits: list[str] = []
    q: deque[str] = deque([task_id])
    while q:
        cur = q.popleft()
        for nxt in store.dependents.get(cur, []):
            if nxt not in claimed:
                claimed.add(nxt)
                hits.append(nxt)
                q.append(nxt)
    return sorted(hits)


def parallel_waves(store: DecompStore) -> list[list[str]]:
    indegree: dict[str, int] = {
        t: len(store.prereqs.get(t, [])) for t in store.tasks
    }
    waves: list[list[str]] = []
    ready = {t for t, d in indegree.items() if d == 0}
    visited: set[str] = set()
    while ready:
        layer = sorted(ready)
        waves.append(layer)
        next_ready: set[str] = set()
        for node in layer:
            visited.add(node)
            for other in store.tasks:
                if node in store.prereqs.get(other, []) and other not in visited:
                    indegree[other] -= 1
                    if indegree[other] == 0:
                        next_ready.add(other)
        ready = next_ready
    if len(visited) != len(store.tasks):
        return []
    return waves


def ready_after(store: DecompStore, completed: list[str]) -> list[str]:
    done = set(completed)
    out: list[str] = []
    for tid in sorted(store.tasks):
        if tid in done:
            continue
        if all(p in done for p in store.prereqs.get(tid, [])):
            out.append(tid)
    return out


def match_agents(store: DecompStore) -> dict[str, str]:
    assignment: dict[str, str] = {}
    for tid in sorted(store.tasks):
        need = store.required_skill.get(tid, "")
        if not need:
            continue
        for agent in sorted(store.agent_skills):
            if need in store.agent_skills[agent]:
                assignment[tid] = agent
                break
    return assignment


def coverage_ratio(store: DecompStore, assignment: dict[str, str]) -> float:
    if not store.tasks:
        return 1.0
    matched = sum(1 for t in store.tasks if t in assignment)
    return matched / len(store.tasks)


def has_dependency_cycle(store: DecompStore) -> bool:
    white, gray, black = 0, 1, 2
    color: dict[str, int] = {t: white for t in store.tasks}

    def dfs(node: str) -> bool:
        color[node] = gray
        for dep in store.prereqs.get(node, []):
            if color[dep] == gray:
                return True
            if color[dep] == white and dfs(dep):
                return True
        color[node] = black
        return False

    for tid in sorted(store.tasks):
        if color[tid] == white and dfs(tid):
            return True
    return False
