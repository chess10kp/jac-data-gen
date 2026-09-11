"""teamleaderleo/preflight#652 — Release milestone parent-child gate tree.

Beta convergence milestones use parent pointers; ascent walk returns the
blocking chain that must complete before a release phase unlocks.
"""

from __future__ import annotations


class ReleaseTree:
    def __init__(self) -> None:
        self.parent_of: dict[str, str | None] = {}
        self.children_of: dict[str, list[str]] = {}


def load_release_tree(
    milestones: list[str],
    parent_edges: list[tuple[str, str]],
) -> ReleaseTree:
    tree = ReleaseTree()
    for mid in milestones:
        tree.parent_of.setdefault(mid, None)
        tree.children_of.setdefault(mid, [])
    for parent, child in parent_edges:
        if parent in tree.parent_of and child in tree.parent_of:
            tree.parent_of[child] = parent
            tree.children_of.setdefault(parent, []).append(child)
    return tree


def blocking_chain(tree: ReleaseTree, milestone_id: str) -> list[str]:
    if milestone_id not in tree.parent_of:
        return []
    chain: list[str] = []
    cur: str | None = milestone_id
    seen: set[str] = set()
    while cur is not None:
        if cur in seen:
            break
        seen.add(cur)
        chain.append(cur)
        cur = tree.parent_of.get(cur)
    chain.reverse()
    return chain


def next_unlocked(tree: ReleaseTree, completed: list[str]) -> list[str]:
    done = set(completed)
    unlocked: list[str] = []
    for mid in sorted(tree.parent_of):
        if mid in done:
            continue
        blockers = [b for b in blocking_chain(tree, mid) if b != mid]
        if all(b in done for b in blockers):
            unlocked.append(mid)
    return unlocked
