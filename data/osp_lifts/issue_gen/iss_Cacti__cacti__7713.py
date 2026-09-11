"""Cacti/cacti#7713 — Recursive file tree collection with ignore set."""

from __future__ import annotations


class FileIndex:
    def __init__(self) -> None:
        self._paths: dict[str, bool] = {}


def load_index(entries: list[tuple[str, bool]]) -> FileIndex:
    idx = FileIndex()
    for path, is_dir in entries:
        idx._paths[path] = is_dir
    return idx


def is_ignored(path: str, ignore: set[str]) -> bool:
    for pat in ignore:
        if path == pat or path.startswith(pat + "/"):
            return True
    return False


def _children_of(idx: FileIndex, parent: str) -> list[str]:
    prefix = "" if parent == "" else parent + "/"
    kids: set[str] = set()
    for path in idx._paths:
        if not path.startswith(prefix):
            continue
        rest = path[len(prefix):]
        if not rest:
            continue
        if "/" in rest:
            first = rest.split("/")[0]
            key = first if parent == "" else prefix + first
            kids.add(key)
        else:
            kids.add(path)
    return sorted(kids)


def collect_files(idx: FileIndex, root_path: str, ignore: set[str]) -> list[str]:
    if root_path and root_path not in idx._paths and not any(
        p.startswith(root_path + "/") for p in idx._paths
    ):
        return []
    hits: list[str] = []
    stack = [root_path]
    claimed: set[str] = set()
    while stack:
        cur = stack.pop()
        if cur in claimed:
            continue
        claimed.add(cur)
        if cur and not idx._paths.get(cur, False):
            if not is_ignored(cur, ignore):
                hits.append(cur)
        for child in reversed(_children_of(idx, cur)):
            if child not in claimed:
                stack.append(child)
    return sorted(hits)
