"""leynos/ortho-config#439 — bounded configuration extends inheritance chain.

Config files extend parents recursively; cycles must error and depth must be
capped. The store keeps parent pointers plus a children adjacency map and
resolves layers with an iterative queue walk instead of unbounded recursion.
"""

from __future__ import annotations

from collections import deque


class CycleError(Exception):
    pass


class DepthError(Exception):
    pass


class ConfigStore:
    def __init__(self) -> None:
        self.parent_of: dict[str, str | None] = {}
        self.children_of: dict[str, list[str]] = {}
        self.keys_of: dict[str, list[str]] = {}

    def add_config(self, name: str, keys: list[str], parent: str | None = None) -> None:
        if parent is not None and parent not in self.parent_of:
            raise KeyError("unknown parent config")
        self.parent_of[name] = parent
        self.children_of.setdefault(name, [])
        if parent is not None:
            self.children_of.setdefault(parent, []).append(name)
        self.keys_of[name] = list(keys)

    def _ancestry_chain(self, name: str, max_depth: int) -> list[str]:
        if name not in self.parent_of:
            raise KeyError("unknown config")
        chain: list[str] = [name]
        active: set[str] = {name}
        cur = self.parent_of.get(name)
        depth = 0
        while cur is not None:
            if cur in active:
                raise CycleError("extends cycle")
            depth += 1
            if depth > max_depth:
                raise DepthError("extends depth exceeded")
            chain.append(cur)
            active.add(cur)
            cur = self.parent_of.get(cur)
        return chain

    def resolve_layers(self, name: str, max_depth: int) -> list[str]:
        return list(reversed(self._ancestry_chain(name, max_depth)))

    def flatten_keys(self, name: str, max_depth: int) -> list[str]:
        layers = self.resolve_layers(name, max_depth)
        seen: set[str] = set()
        out: list[str] = []
        for layer in layers:
            for k in self.keys_of.get(layer, []):
                if k not in seen:
                    seen.add(k)
                    out.append(k)
        return out

    def descendant_configs(self, name: str) -> list[str]:
        if name not in self.parent_of:
            raise KeyError("unknown config")
        seen: set[str] = set()
        q: deque[str] = deque([name])
        out: list[str] = []
        while q:
            cur = q.popleft()
            if cur in seen:
                continue
            seen.add(cur)
            out.append(cur)
            for ch in self.children_of.get(cur, []):
                q.append(ch)
        return sorted(out)
