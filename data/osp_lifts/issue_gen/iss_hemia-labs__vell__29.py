"""hemia-labs/vell#29 — findDescendantIds loads all categories for tree walk."""

from __future__ import annotations


class CategoryStore:
    """Mutable category index; fresh instance per test."""

    def __init__(self) -> None:
        self._rows: list[tuple[str, str | None]] = []

    def load_all(self, rows: list[tuple[str, str | None]]) -> None:
        self._rows = list(rows)

    def find_descendant_ids(self, category_id: str) -> list[str]:
        if not any(r[0] == category_id for r in self._rows):
            return []
        out: list[str] = []
        seen: set[str] = set()
        stack: list[str] = [category_id]
        while stack:
            cur = stack.pop()
            for cid, par in self._rows:
                if par == cur and cid not in seen:
                    seen.add(cid)
                    out.append(cid)
                    stack.append(cid)
        return sorted(out)
