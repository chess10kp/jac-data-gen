"""jmassardo/agentic-sdlc#1 — Agent orchestration handoff graph.

Parent orchestrator pointers plus invokes adjacency for bounded workflow
transitions; BFS collects reachable agents and DFS detects recursive handoffs.
"""

from __future__ import annotations

from collections import deque


class AgentStore:
    def __init__(self) -> None:
        self.agents: set[str] = set()
        self.handoffs: dict[str, list[str]] = {}


def load_agents(
    names: list[str],
    handoff_edges: list[tuple[str, str]],
) -> AgentStore:
    store = AgentStore()
    for name in names:
        store.agents.add(name)
        store.handoffs.setdefault(name, [])
    for src, dst in handoff_edges:
        if src in store.agents and dst in store.agents:
            store.handoffs.setdefault(src, []).append(dst)
    return store


def reachable_agents(store: AgentStore, start: str) -> list[str]:
    if start not in store.agents:
        return []
    seen: set[str] = set()
    queue: deque[str] = deque([start])
    while queue:
        cur = queue.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in store.handoffs.get(cur, []):
            if nxt not in seen:
                queue.append(nxt)
    return sorted(seen)


def detect_handoff_cycles(store: AgentStore) -> list[tuple[str, str]]:
    errors: list[tuple[str, str]] = []
    visited: set[str] = set()
    stack: set[str] = set()

    def dfs(node: str) -> None:
        visited.add(node)
        stack.add(node)
        for nxt in store.handoffs.get(node, []):
            if nxt in stack:
                errors.append((node, nxt))
            elif nxt not in visited:
                dfs(nxt)
        stack.remove(node)

    for agent in sorted(store.agents):
        if agent not in visited:
            dfs(agent)
    return sorted(errors)
