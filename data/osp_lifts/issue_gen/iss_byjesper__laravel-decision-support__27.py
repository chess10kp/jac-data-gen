"""Synthetic before-code for byjesper/laravel-decision-support#27.

RunState.has_visited() performs an O(N) linear scan over path on every call.
GuideRunner's acyclic revisit guard invokes it once per transition.
"""
from __future__ import annotations

from collections import deque


def _linear_contains(path: list[str], node_key: str) -> bool:
    for step in path:
        if step == node_key:
            return True
    return False


class RunState:
    def __init__(self, path: list[str], cursor: str) -> None:
        self._path = path
        self._cursor = cursor

    def path_keys(self) -> list[str]:
        return list(self._path)

    def cursor_key(self) -> str:
        return self._cursor

    def has_visited(self, node_key: str) -> bool:
        return _linear_contains(self._path, node_key)

    def move_to(self, node_key: str) -> RunState:
        return RunState(self._path + [node_key], node_key)

    def copy(self) -> RunState:
        return RunState(list(self._path), self._cursor)


class FrontierEntry:
    def __init__(self, node_key: str, state: RunState) -> None:
        self.node_key = node_key
        self.state = state


class GuideNode:
    def __init__(self, key: str) -> None:
        self.key = key


class GuideDefinition:
    def __init__(self, edges: dict[str, list[str]]) -> None:
        self.nodes: dict[str, GuideNode] = {}
        self.edges = {o: list(ts) for o, ts in edges.items()}
        for origin in sorted(self.edges.keys()):
            self._ensure(origin)
            for target in self.edges[origin]:
                self._ensure(target)

    def _ensure(self, key: str) -> None:
        if key not in self.nodes:
            self.nodes[key] = GuideNode(key=key)

    def edges_from(self, origin: str) -> list[str]:
        stored = self.edges.get(origin, None)
        if stored is None:
            return []
        return list(stored)

    def node_keys(self) -> list[str]:
        discovered: list[str] = []
        seen: dict[str, bool] = {}
        for origin in sorted(self.edges.keys()):
            if origin not in seen:
                seen[origin] = True
                discovered.append(origin)
            for target in self.edges[origin]:
                if target not in seen:
                    seen[target] = True
                    discovered.append(target)
        return discovered


def _run_to_bfs(edge_lists: dict[str, list[str]], acyclic: bool, goal: str, frontier: list[FrontierEntry]) -> RunState | None:
    q: deque[FrontierEntry] = deque(frontier)
    while q:
        item = q.popleft()
        if item.node_key == goal:
            return item.state
        for nxt_key in edge_lists.get(item.node_key, []):
            if acyclic and item.state.has_visited(nxt_key):
                continue
            q.append(FrontierEntry(nxt_key, item.state.move_to(nxt_key)))
    return None


def _reach_bfs(edge_lists: dict[str, list[str]], acyclic: bool, frontier: list[FrontierEntry], order: list[str], claimed: dict[str, bool]) -> None:
    q: deque[FrontierEntry] = deque(frontier)
    while q:
        item = q.popleft()
        if item.node_key not in claimed:
            claimed[item.node_key] = True
            order.append(item.node_key)
        for nxt_key in edge_lists.get(item.node_key, []):
            if acyclic and item.state.has_visited(nxt_key):
                continue
            if nxt_key in claimed:
                continue
            q.append(FrontierEntry(nxt_key, item.state.move_to(nxt_key)))


class GuideRunner:
    def __init__(self, guide: GuideDefinition, acyclic: bool = True) -> None:
        self.guide = guide
        self.acyclic = acyclic

    def run_to(self, start: str, goal: str) -> RunState | None:
        return _run_to_bfs(self.guide.edges, self.acyclic, goal, [FrontierEntry(start, RunState([start], start))])

    def reachable_keys(self, start: str) -> list[str]:
        order: list[str] = []
        claimed: dict[str, bool] = {}
        _reach_bfs(self.guide.edges, self.acyclic, [FrontierEntry(start, RunState([start], start))], order, claimed)
        return order

    def transition_guard_calls(self, start: str) -> int:
        calls = 0
        state = RunState([start], start)
        for nxt in self.guide.edges_from(start):
            calls += 1
            if self.acyclic and state.has_visited(nxt):
                continue
        for nxt in self.guide.edges_from(start):
            child = state.move_to(nxt)
            for leaf in self.guide.edges_from(nxt):
                calls += 1
                if self.acyclic and child.has_visited(leaf):
                    continue
        return calls
