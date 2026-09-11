"""opena2a-org/hackmyagent#379 — parse-offset grant line citation (structure over text)."""
from __future__ import annotations

from collections import deque


class ConfigKey:
    def __init__(
        self,
        cid: str,
        key_name: str,
        full_path: str,
        line: int,
        polarity: str,
        grant_value: str,
        depth: int = 0,
    ) -> None:
        self.cid = cid
        self.key_name = key_name
        self.full_path = full_path
        self.line = line
        self.polarity = polarity
        self.grant_value = grant_value
        self.depth = depth


_ADJ: dict[str, list[ConfigKey]] = {}


def _children(parent: ConfigKey) -> list[ConfigKey]:
    out: list[ConfigKey] = []
    for ch in _ADJ.get(parent.cid, []):
        out.append(ch)
    return out


def _dfs(graph_root: ConfigKey, step_fn) -> None:
    queue: deque[ConfigKey] = deque([graph_root])
    while len(queue) > 0:
        here = queue.popleft()
        step_fn(here, queue)


def connect_child(parent: ConfigKey, child: ConfigKey) -> None:
    if parent.cid not in _ADJ:
        _ADJ[parent.cid] = []
    _ADJ[parent.cid].append(child)


def build_issue_tree() -> ConfigKey:
    _ADJ.clear()
    graph_root = ConfigKey("n0", "root", "", 0, "none", "", 0)
    perms = ConfigKey("n1", "permissions", "permissions", 2, "none", "", 1)
    allow0 = ConfigKey("n2", "allow[0]", "permissions.allow[0]", 3, "allow", "Read(src/**)", 2)
    deny0 = ConfigKey("n3", "deny[0]", "permissions.deny[0]", 4, "deny", "Read(**/*.key)", 2)
    extra = ConfigKey("n5", "extra", "permissions.extra", 5, "none", "", 2)
    extra_allow = ConfigKey("n4", "allow[0]", "permissions.extra.allow[0]", 5, "allow", "Read(**/*.key)", 3)
    connect_child(graph_root, perms)
    connect_child(perms, allow0)
    connect_child(perms, deny0)
    connect_child(perms, extra)
    connect_child(extra, extra_allow)
    return graph_root


def build_diamond_tree() -> ConfigKey:
    _ADJ.clear()
    graph_root = ConfigKey("r0", "root", "", 0, "none", "", 0)
    apex = ConfigKey("r1", "permissions", "permissions", 1, "none", "", 1)
    left = ConfigKey("r2", "left", "permissions.left", 2, "none", "", 2)
    right = ConfigKey("r3", "right", "permissions.right", 3, "none", "", 2)
    shared = ConfigKey("alias_shared", "grant", "permissions.shared.grant", 7, "allow", "Read(**/*.key)", 3)
    connect_child(graph_root, apex)
    connect_child(apex, left)
    connect_child(apex, right)
    connect_child(left, shared)
    connect_child(right, shared)
    return graph_root


def grant_line_at(graph_root: ConfigKey, path: str, depth_limit: int = -1) -> int | None:
    found_line = -1
    claimed: dict[str, bool] = {}

    def step(here: ConfigKey, queue: deque[ConfigKey]) -> None:
        nonlocal found_line
        if here.cid in claimed:
            return
        claimed[here.cid] = True
        if depth_limit >= 0 and here.depth > depth_limit:
            print("bounded ", here.full_path)
        elif here.full_path == path and here.grant_value != "":
            found_line = here.line
            print("line_hit ", here.full_path, " ", here.line)
        kids = _children(here)
        for ch in kids:
            queue.appendleft(ch)

    _dfs(graph_root, step)
    if found_line < 0:
        return None
    return found_line


def structure_locate(graph_root: ConfigKey, value: str, polarity: str) -> int | None:
    found_line = -1
    claimed: dict[str, bool] = {}

    def probe(here: ConfigKey, queue: deque[ConfigKey]) -> None:
        nonlocal found_line
        if here.cid in claimed:
            return
        claimed[here.cid] = True
        if here.grant_value == value and here.polarity == polarity:
            found_line = here.line
            print("value_hit ", here.polarity, " ", here.line)
        kids = _children(here)
        for ch in kids:
            queue.appendleft(ch)

    _dfs(graph_root, probe)
    if found_line < 0:
        return None
    return found_line


def collect_allow_lines(graph_root: ConfigKey, max_depth: int) -> list[str]:
    paths: list[str] = []
    claimed: dict[str, bool] = {}

    def gather(here: ConfigKey, queue: deque[ConfigKey]) -> None:
        if here.cid in claimed:
            return
        if here.depth > max_depth:
            print("depth_skip ", here.full_path)
            return
        claimed[here.cid] = True
        if here.polarity == "allow" and here.grant_value != "":
            paths.append(here.full_path)
            print("allow ", here.full_path, " ", here.line)
        kids = _children(here)
        for ch in kids:
            queue.appendleft(ch)

    _dfs(graph_root, gather)
    out: list[str] = []
    for p in paths:
        out.append(p)
    return sorted(out)
