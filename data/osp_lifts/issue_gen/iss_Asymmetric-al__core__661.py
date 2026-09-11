"""Asymmetric-al/core#661 — Safe archive/delete + dependency map + cleanup view.

Hand-rolled parent/child adjacency, stack subtree collection, dependency
reverse-index, and two-phase archive-or-hard-delete with progress probe.
"""

from __future__ import annotations


class ArchiveError(ValueError):
    pass


class AssetGraph:
    def __init__(self) -> None:
        self._kind: dict[str, str] = {}          # asset -> "pkg" | "view"
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._depends: dict[str, list[str]] = {}  # asset -> upstream deps
        self._archived: set[str] = set()
        self._referenced: set[str] = set()        # assets with live refs

    def add_pkg(self, name: str, parent: str | None = None) -> None:
        if parent is not None and parent not in self._kind:
            raise KeyError("unknown parent")
        self._kind[name] = "pkg"
        self._parent[name] = parent
        self._children.setdefault(name, [])
        if parent is not None:
            self._children.setdefault(parent, []).append(name)

    def add_view(self, name: str, depends: list[str]) -> None:
        self._kind[name] = "view"
        self._parent[name] = None
        self._children.setdefault(name, [])
        self._depends[name] = list(depends)
        for up in depends:
            self._referenced.add(up)

    def dependency_map(self, name: str) -> dict[str, list[str]]:
        if name not in self._kind:
            return {"upstream": [], "downstream": []}
        upstream = sorted(self._depends.get(name, []))
        downstream: list[str] = []
        for asset, deps in self._depends.items():
            if name in deps:
                downstream.append(asset)
        return {"upstream": upstream, "downstream": sorted(downstream)}

    def _subtree(self, root: str) -> list[str]:
        out: list[str] = []
        stack = [root]
        seen: set[str] = set()
        while stack:
            cur = stack.pop()
            if cur in seen:
                continue
            seen.add(cur)
            out.append(cur)
            stack.extend(self._children.get(cur, []))
        return sorted(out)

    def safe_remove(self, root: str) -> tuple[str, list[str]]:
        if self._kind.get(root) != "pkg":
            raise KeyError("unknown package")
        doomed = self._subtree(root)
        touched = sorted(
            a for a in doomed
            if a in self._referenced and a not in self._archived
        )
        if touched:
            for n in doomed:
                self._archived.add(n)
            return "archived", doomed
        parent = self._parent.get(root)
        if parent is not None:
            self._children[parent] = [
                c for c in self._children.get(parent, []) if c != root
            ]
        for n in doomed:
            self._kind.pop(n, None)
            self._parent.pop(n, None)
            self._children.pop(n, None)
            self._depends.pop(n, None)
            self._archived.discard(n)
        return "deleted", doomed

    def cleanup_view(self) -> list[str]:
        return sorted(
            n for n in self._kind
            if n not in self._archived
        )
