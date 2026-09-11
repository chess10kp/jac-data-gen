"""agentarea/agentarea#143 — Async agent delegation with cascading pause/resume/cancel."""

from __future__ import annotations

from collections import deque


class AgentRuntime:
    def __init__(self) -> None:
        self._agents: set[str] = set()
        self._delegates: dict[str, list[str]] = {}
        self._manager: dict[str, str | None] = {}
        self._state: dict[str, str] = {}
        self._refs: dict[str, list[str]] = {}


def build_runtime(
    agents: list[str],
    delegates: list[tuple[str, str]],
    refs: list[tuple[str, str]] | None = None,
) -> AgentRuntime:
    rt = AgentRuntime()
    for name in agents:
        rt._agents.add(name)
        rt._delegates.setdefault(name, [])
        rt._manager[name] = None
        rt._state[name] = "running"
        rt._refs.setdefault(name, [])
    for mgr, sub in delegates:
        if mgr in rt._agents and sub in rt._agents:
            rt._delegates.setdefault(mgr, []).append(sub)
            if rt._manager[sub] is None:
                rt._manager[sub] = mgr
    for src, dst in refs or []:
        if src in rt._agents and dst in rt._agents:
            rt._refs[src].append(dst)
    return rt


def _subtree_bfs(rt: AgentRuntime, root: str) -> list[str]:
    if root not in rt._agents:
        return []
    q: deque[str] = deque([root])
    claimed: set[str] = set()
    hits: list[str] = []
    while q:
        cur = q.popleft()
        if cur in claimed:
            continue
        claimed.add(cur)
        hits.append(cur)
        for child in rt._delegates.get(cur, []):
            if child not in claimed:
                q.append(child)
    return hits


def delegated_subtree(rt: AgentRuntime, manager: str) -> list[str]:
    return sorted(_subtree_bfs(rt, manager))


def _ancestors_running(rt: AgentRuntime, agent: str) -> bool:
    seen: set[str] = set()
    cur = rt._manager.get(agent)
    while cur is not None:
        if cur in seen:
            break
        seen.add(cur)
        if rt._state.get(cur) != "running":
            return False
        cur = rt._manager.get(cur)
    return True


def cascade_pause(rt: AgentRuntime, agent: str) -> list[str]:
    changed: list[str] = []
    for name in _subtree_bfs(rt, agent):
        if rt._state.get(name) == "running":
            rt._state[name] = "paused"
            changed.append(name)
    return sorted(changed)


def cascade_resume(rt: AgentRuntime, agent: str) -> list[str]:
    changed: list[str] = []
    for name in _subtree_bfs(rt, agent):
        if rt._state.get(name) != "paused":
            continue
        if not _ancestors_running(rt, name):
            continue
        rt._state[name] = "running"
        changed.append(name)
    return sorted(changed)


def cascade_cancel(rt: AgentRuntime, agent: str) -> list[str]:
    changed: list[str] = []
    for name in _subtree_bfs(rt, agent):
        if rt._state.get(name) != "cancelled":
            rt._state[name] = "cancelled"
            changed.append(name)
    return sorted(changed)


def agent_state(rt: AgentRuntime, agent: str) -> str | None:
    if agent not in rt._agents:
        return None
    return rt._state[agent]


def ref_violations(rt: AgentRuntime, manager: str) -> list[str]:
    if manager not in rt._agents:
        return []
    scope = set(_subtree_bfs(rt, manager))
    violations: list[str] = []
    for src in sorted(scope):
        for dst in rt._refs.get(src, []):
            if dst not in scope:
                violations.append(f"{src}->{dst}")
    return sorted(violations)
