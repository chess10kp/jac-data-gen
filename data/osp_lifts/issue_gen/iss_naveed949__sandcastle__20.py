"""naveed949/sandcastle#20 — Unified multi-repository workflows and Mission Control."""

from __future__ import annotations

from collections import deque


class MissionHandle:
    def __init__(self) -> None:
        self._repos: set[str] = set()
        self._depends: dict[str, list[str]] = {}
        self._blocked: set[str] = set()


def load_mission(
    repos: list[str],
    depends: list[tuple[str, str]],
    blocked: list[str] | None = None,
) -> MissionHandle:
    m = MissionHandle()
    for r in repos:
        m._repos.add(r)
        m._depends.setdefault(r, [])
    for repo, dep in depends:
        if repo not in m._repos or dep not in m._repos:
            raise KeyError("unknown repo")
        m._depends[repo].append(dep)
    m._blocked = set(blocked or [])
    return m


def repo_build_order(m: MissionHandle) -> list[str] | None:
    indeg = {r: len(m._depends.get(r, [])) for r in m._repos}
    out: list[str] = []
    ready = sorted(r for r, d in indeg.items() if d == 0)
    while ready:
        out.extend(ready)
        nxt: list[str] = []
        for u in ready:
            for v in m._repos:
                if u in m._depends.get(v, []):
                    indeg[v] -= 1
                    if indeg[v] == 0:
                        nxt.append(v)
        ready = sorted(nxt)
    return out if len(out) == len(m._repos) else None


def blocked_repos(m: MissionHandle) -> list[str]:
    blocked: set[str] = set(m._blocked)
    q: deque[str] = deque(sorted(m._blocked))
    while q:
        cur = q.popleft()
        for repo in sorted(m._repos):
            if repo in blocked:
                continue
            if cur in m._depends.get(repo, []):
                blocked.add(repo)
                q.append(repo)
    return sorted(blocked)
