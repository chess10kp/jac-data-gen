"""EXXETA/exxperts#49 — recursive skill directory scan with symlink cycle guard."""
import from __future__ { annotations }
import from collections { deque }
glob MAX_SCAN: int = 256;
class SkillIndex {
    def init(self: SkillIndex) -> None {
        self._dirs: set[str] = set();
        self._children: dict[(str, list[str])] = {};
        self._has_skill: dict[(str, bool)] = {};
        self._symlinks: dict[(str, str)] = {};
    }
}
def load_skill_index(
    dirs: list[str],
    child_edges: list[tuple[(str, str)]],
    symlinks: (list[tuple[(str, str)]] | None) = None,
    skill_dirs: (list[str] | None) = None
) -> SkillIndex {
    idx = SkillIndex();
    for d in dirs {
        idx._dirs.add(d);
        idx._children.setdefault(d, []);
        idx._has_skill[d] = False;
    }
    for (parent, child) in child_edges {
        if ((parent in idx._dirs) and (child in idx._dirs)) {
            idx._children.setdefault(parent, []).append(child);
        }
    }
    if symlinks {
        for (link, target) in symlinks {
            if ((link in idx._dirs) and (target in idx._dirs)) {
                idx._symlinks[link] = target;
            }
        }
    }
    if skill_dirs {
        for d in skill_dirs {
            if (d in idx._dirs) {
                idx._has_skill[d] = True;
            }
        }
    }
    return idx;
}
def _resolve(idx: SkillIndex, path: str, seen_links: set[str]) -> str {
    while (path in idx._symlinks) {
        if (path in seen_links) {
            return path;
        }
        seen_links.add(path);
        path = idx._symlinks[path];
    }
    return path;
}
def discover_skills(idx: SkillIndex, `root: str) -> list[str] {
    if (`root not in idx._dirs) {
        return [];
    }
    found: list[str] = [];
    visited: set[str] = set();
    queue: deque[str] = deque([`root]);
    steps = 0;
    while (queue and (steps < MAX_SCAN)) {
        steps += 1;
        cur = queue.popleft();
        canon = _resolve(idx, cur, set());
        if (canon in visited) {
            continue;
        }
        visited.add(canon);
        if idx._has_skill.get(canon, False) {
            found.append(canon);
        }
        for child in idx._children.get(canon, idx._children.get(cur, [])) {
            queue.append(child);
        }
        if (cur in idx._symlinks) {
            queue.append(idx._symlinks[cur]);
        }
    }
    return sorted(found);
}
def scan_visit_count(idx: SkillIndex, `root: str) -> int {
    if (`root not in idx._dirs) {
        return 0;
    }
    visited: set[str] = set();
    queue: deque[str] = deque([`root]);
    steps = 0;
    while (queue and (steps < MAX_SCAN)) {
        steps += 1;
        cur = queue.popleft();
        canon = _resolve(idx, cur, set());
        if (canon in visited) {
            continue;
        }
        visited.add(canon);
        for child in idx._children.get(canon, []) {
            queue.append(child);
        }
        if (cur in idx._symlinks) {
            queue.append(idx._symlinks[cur]);
        }
    }
    return len(visited);
}
def has_symlink_cycle(idx: SkillIndex, `root: str) -> bool {
    if (`root not in idx._dirs) {
        return False;
    }
    visited: set[str] = set();
    queue: deque[str] = deque([`root]);
    steps = 0;
    while (queue and (steps < MAX_SCAN)) {
        steps += 1;
        cur = queue.popleft();
        link_seen: set[str] = set();
        canon = _resolve(idx, cur, link_seen);
        if ((len(link_seen) > 0) and (canon in link_seen)) {
            return True;
        }
        if (canon in visited) {
            continue;
        }
        visited.add(canon);
        for child in idx._children.get(canon, []) {
            queue.append(child);
        }
        if (cur in idx._symlinks) {
            queue.append(idx._symlinks[cur]);
        }
    }
    return False;
}

