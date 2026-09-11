"""C360Studio/semstreams#230 — dependency coordinate reachability for resolver workflow.

Coordinate resolver walks the module dependency graph from entry packages and
flags packages lacking verified coordinates. Adjacency dict plus stack walk
with visited set; unreachable orphans are reported separately.
"""

from __future__ import annotations


class DepStore:
    def __init__(self) -> None:
        self.packages: dict[str, bool] = {}
        self.deps: dict[str, list[str]] = {}
        self.coords: dict[str, str | None] = {}

    def add_package(self, name: str, coord: str | None) -> None:
        self.packages[name] = True
        self.deps.setdefault(name, [])
        self.coords[name] = coord

    def add_dep(self, src: str, dst: str) -> None:
        if src in self.packages and dst in self.packages:
            self.deps[src].append(dst)


def load_packages(
    packages: list[tuple[str, str | None]],
    edges: list[tuple[str, str]],
) -> DepStore:
    st = DepStore()
    for name, coord in packages:
        st.add_package(name, coord)
    for src, dst in edges:
        st.add_dep(src, dst)
    return st


def reachable_packages(st: DepStore, roots: list[str]) -> list[str]:
    seen: set[str] = set()
    stack: list[str] = []
    for r in roots:
        if r in st.packages:
            stack.append(r)
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in st.deps.get(cur, []):
            if nxt not in seen:
                stack.append(nxt)
    return sorted(seen)


def unverified_coordinates(st: DepStore, roots: list[str]) -> list[str]:
    reach = set(reachable_packages(st, roots))
    return sorted(p for p in reach if not st.coords.get(p))
