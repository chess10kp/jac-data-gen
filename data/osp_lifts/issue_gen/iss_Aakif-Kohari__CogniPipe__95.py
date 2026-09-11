"""Aakif-Kohari/CogniPipe#95 — Workflow dependsOn cycle detection (three-colour DFS)."""

from __future__ import annotations


class StepStore:
    def __init__(self) -> None:
        self._steps: dict[str, list[str]] = {}


def load_steps(steps: list[tuple[str, list[str]]]) -> StepStore:
    store = StepStore()
    for name, deps in steps:
        store._steps[name] = list(deps)
    return store


def detect_cycles(store: StepStore) -> list[str]:
    white = set(store._steps)
    gray: set[str] = set()
    black: set[str] = set()
    cycles: list[str] = []

    def dfs(node: str, stack: list[str]) -> None:
        if node in black:
            return
        if node in gray:
            if stack:
                cycles.append("Circular dependency: " + " -> ".join(stack + [node]))
            return
        gray.add(node)
        stack.append(node)
        for dep in store._steps.get(node, []):
            if dep not in store._steps:
                continue
            dfs(dep, stack)
        stack.pop()
        gray.remove(node)
        black.add(node)

    for name in sorted(white):
        if name not in black:
            dfs(name, [])
    return cycles
