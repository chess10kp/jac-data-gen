"""anadon/JLS#612 — confined .dig import workflow DAG and path reachability."""

from __future__ import annotations

from collections import deque


class DigWorkflow:
    def __init__(self) -> None:
        self.sections: dict[str, list[str]] = {}
        self.nodes: dict[str, str] = {}
        self._depends: dict[str, list[str]] = {}

    def add_section(self, section_id: str, test_vectors: list[str] | None = None) -> None:
        if section_id not in self.sections:
            self.sections[section_id] = []
        if test_vectors:
            for v in test_vectors:
                self.sections[section_id].append(v)
        if section_id not in self.nodes:
            self.nodes[section_id] = section_id
        self._depends.setdefault(section_id, [])

    def add_dependency(self, consumer: str, depends_on: str) -> None:
        if consumer in self.sections and depends_on in self.sections:
            self._depends.setdefault(consumer, []).append(depends_on)


def load_dig_workflow(
    sections: list[tuple[str, list[str]]],
    edges: list[tuple[str, str]],
) -> DigWorkflow:
    graph = DigWorkflow()
    for section_id, vectors in sections:
        graph.add_section(section_id, vectors)
    for consumer, depends_on in edges:
        graph.add_dependency(consumer, depends_on)
    return graph


def transitive_dependencies(graph: DigWorkflow, root: str) -> list[str]:
    if root not in graph.sections:
        return []
    seen: set[str] = set()
    queue: deque[str] = deque([root])
    while queue:
        cur = queue.popleft()
        for dep in sorted(graph._depends.get(cur, [])):
            if dep not in seen:
                seen.add(dep)
                queue.append(dep)
    return sorted(seen)


def downstream_tasks(graph: DigWorkflow, root: str) -> list[str]:
    if root not in graph.sections:
        return []
    rev: dict[str, list[str]] = {sid: [] for sid in graph.sections}
    for consumer, deps in graph._depends.items():
        for dep in deps:
            if dep in rev:
                rev[dep].append(consumer)
    seen: set[str] = set()
    queue: deque[str] = deque([root])
    while queue:
        cur = queue.popleft()
        for nxt in sorted(rev.get(cur, [])):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)


def dependency_paths(
    graph: DigWorkflow,
    source: str,
    target: str,
    *,
    max_depth: int = 12,
) -> list[list[str]]:
    if source not in graph.sections or target not in graph.sections:
        return []
    paths: list[list[str]] = []

    def walk(here: str, trail: list[str]) -> None:
        if here in trail:
            return
        nt = trail + [here]
        if here == target:
            paths.append(list(nt))
            return
        if len(nt) >= max_depth:
            return
        for dep in sorted(graph._depends.get(here, [])):
            walk(dep, nt)

    walk(source, [])
    return sorted(paths)


def preserved_test_vectors(graph: DigWorkflow, section_id: str) -> list[str]:
    if section_id not in graph.sections:
        return []
    return sorted(graph.sections[section_id])
