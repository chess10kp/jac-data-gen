"""Naive hand-rolled implementation for VOID-TECHNOLOGY-INC/PyBun#404."""


def scan_directory(
    root_id: str,
    directories: list[tuple[str, str]],
    module_ids: list[str],
) -> list[str]:
    nodes: set[str] = set()
    adjacency: dict[str, list[str]] = {}
    parent: dict[str, str | None] = {}

    nodes.add(root_id)
    adjacency[root_id] = []
    parent[root_id] = None

    for source_id, target_id in directories:
        if source_id not in nodes:
            nodes.add(source_id)
            adjacency[source_id] = []
            parent[source_id] = None
        if target_id not in nodes:
            nodes.add(target_id)
            adjacency[target_id] = []
            parent[target_id] = None

    modules: set[str] = set()
    for module_id in module_ids:
        if module_id in nodes:
            modules.add(module_id)

    for source_id, target_id in directories:
        if source_id in nodes and target_id in nodes:
            adjacency[source_id].append(target_id)

    found: list[str] = []
    claimed: set[str] = set()
    pending: deque[str]

    from collections import deque

    pending = deque([root_id])
    while pending:
        current = pending.popleft()
        if current in claimed:
            continue

        claimed.add(current)
        print("scanned " + current)

        if current in modules:
            found.append(current)

        children = adjacency.get(current, [])
        for child in reversed(children):
            parent[child] = current
            pending.appendleft(child)

    return sorted(found)
