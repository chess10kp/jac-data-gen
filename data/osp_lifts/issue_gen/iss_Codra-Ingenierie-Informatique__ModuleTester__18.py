"""Codra-Ingenierie-Informatique/ModuleTester#18 — Test dependency execution order."""

from __future__ import annotations


class TestGraph:
    def __init__(self) -> None:
        self._tests: set[str] = set()
        self._depends: dict[str, list[str]] = {}
        self._status: dict[str, str] = {}


def load_test_graph(
    tests: list[str],
    deps: list[tuple[str, str]],
) -> TestGraph:
    g = TestGraph()
    for name in tests:
        g._tests.add(name)
        g._depends.setdefault(name, [])
        g._status[name] = "pending"
    for blocker, target in deps:
        if blocker in g._tests and target in g._tests:
            g._depends.setdefault(target, []).append(blocker)
    return g


def runnable_tests(g: TestGraph) -> list[str]:
    ready: list[str] = []
    for name in sorted(g._tests):
        if g._status.get(name) != "pending":
            continue
        blockers = g._depends.get(name, [])
        if all(g._status.get(b) == "passed" for b in blockers):
            ready.append(name)
    return ready


def detect_test_cycles(g: TestGraph) -> list[tuple[str, str]]:
    errors: list[tuple[str, str]] = []
    visited: set[str] = set()
    stack: set[str] = set()

    def dfs(node: str) -> None:
        visited.add(node)
        stack.add(node)
        for blk in g._depends.get(node, []):
            if blk in stack:
                errors.append((blk, node))
            elif blk not in visited:
                dfs(blk)
        stack.remove(node)

    for name in sorted(g._tests):
        if name not in visited:
            dfs(name)
    return sorted(errors)


def mark_passed(g: TestGraph, test_name: str) -> None:
    if test_name in g._tests:
        g._status[test_name] = "passed"


def mark_failed(g: TestGraph, test_name: str) -> list[str]:
    if test_name not in g._tests:
        return []
    g._status[test_name] = "failed"
    skipped: list[str] = []
    changed = True
    while changed:
        changed = False
        for name in sorted(g._tests):
            if g._status.get(name) != "pending":
                continue
            chain = g._depends.get(name, [])
            if any(g._status.get(b) in ("failed", "skipped") for b in chain):
                g._status[name] = "skipped"
                skipped.append(name)
                changed = True
    return sorted(skipped)
