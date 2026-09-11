"""seebom-labs/BOMHort#56 — SBOM dependency tree: adjacency + visited-set traversal."""

from collections import deque
from typing import Callable, Dict, List, Optional, Set, Tuple


class DependencyGraph:
    """Hand-rolled dependency graph for hierarchical SBOM tree views."""

    def __init__(self) -> None:
        self._nodes: Dict[str, str] = {}
        self._children: Dict[str, List[str]] = {}
        self._parents: Dict[str, List[str]] = {}

    def add_component(self, component_id: str, name: str) -> None:
        self._nodes[component_id] = name
        self._children.setdefault(component_id, [])
        self._parents.setdefault(component_id, [])

    def add_dependency(self, parent_id: str, child_id: str) -> None:
        if parent_id not in self._nodes or child_id not in self._nodes:
            raise KeyError("unknown component")
        self._children[parent_id].append(child_id)
        self._parents[child_id].append(parent_id)

    def get_name(self, component_id: str) -> str:
        if component_id not in self._nodes:
            raise KeyError("unknown component")
        return self._nodes[component_id]

    def direct_dependencies(self, component_id: str) -> List[str]:
        if component_id not in self._nodes:
            raise KeyError("unknown component")
        return sorted(self._children.get(component_id, []))

    def dependency_closure(self, component_id: str) -> List[str]:
        # BFS with visited-set; cycle-safe via claim map
        if component_id not in self._nodes:
            raise KeyError("unknown component")
        seen: Set[str] = set()
        queue: deque[str] = deque([component_id])
        out: List[str] = []
        while queue:
            cur = queue.popleft()
            if cur in seen:
                continue
            seen.add(cur)
            out.append(cur)
            for child in self._children.get(cur, []):
                if child not in seen:
                    queue.append(child)
        return sorted(out)

    def has_cycle(self) -> bool:
        visited: Set[str] = set()
        stack: Set[str] = set()

        def dfs(node: str) -> bool:
            if node in stack:
                return True
            if node in visited:
                return False
            visited.add(node)
            stack.add(node)
            for child in self._children.get(node, []):
                if dfs(child):
                    return True
            stack.remove(node)
            return False

        for node in self._nodes:
            if dfs(node):
                return True
        return False

    def tree_rows(self, root_id: str) -> List[Tuple[int, str, str]]:
        """Depth-first rows: (depth, id, name) for UI tree view."""
        if root_id not in self._nodes:
            raise KeyError("unknown component")
        rows: List[Tuple[int, str, str]] = []
        seen: Set[str] = set()

        def walk(node: str, depth: int) -> None:
            if node in seen:
                return
            seen.add(node)
            rows.append((depth, node, self._nodes[node]))
            for child in sorted(self._children.get(node, [])):
                walk(child, depth + 1)

        walk(root_id, 0)
        return rows

    def remove_component(self, component_id: str) -> None:
        if component_id not in self._nodes:
            raise KeyError("unknown component")
        # collect first, mutate after traversal
        to_drop = set(self.dependency_closure(component_id))
        for pid in list(self._nodes):
            self._children[pid] = [c for c in self._children.get(pid, []) if c not in to_drop]
            self._parents[pid] = [p for p in self._parents.get(pid, []) if p not in to_drop]
        for cid in to_drop:
            self._nodes.pop(cid, None)
            self._children.pop(cid, None)
            self._parents.pop(cid, None)
