"""oorabona/db-semantic-planner#352 — cross-branch js: read metadata agreement fold."""

from __future__ import annotations


class SchemaFold:
    def __init__(self) -> None:
        self._branches: list[list[dict[str, str | None]]] = []


def load_branch_metadata(
    branches: list[list[dict[str, str | None]]],
) -> SchemaFold:
    fold = SchemaFold()
    fold._branches = [list(row) for row in branches]
    return fold


def fold_js_read_at(fold: SchemaFold, position: int) -> str | None:
    if not fold._branches:
        return None
    width = len(fold._branches[0])
    if position < 0 or position >= width:
        return None
    agreed: str | None = None
    for branch in fold._branches:
        if position >= len(branch):
            return None
        meta = branch[position].get("js")
        if meta is None:
            return None
        if agreed is None:
            agreed = meta
        elif meta != agreed:
            return None
    return agreed


def fold_js_read_metadata(fold: SchemaFold) -> list[str | None]:
    if not fold._branches:
        return []
    width = len(fold._branches[0])
    return [fold_js_read_at(fold, i) for i in range(width)]


def should_convert(fold: SchemaFold, position: int) -> bool:
    return fold_js_read_at(fold, position) is not None
