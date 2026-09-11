"""Cycle-safe lexical scope ownership. Source: ntntlang/ntnt#183."""

from __future__ import annotations


def enter_scope(stack: list[str], scope_id: str, parent: str | None) -> list[str]:
    out = list(stack)
    out.append(scope_id)
    return out


def exit_scope(stack: list[str]) -> list[str]:
    if not stack:
        return []
    return stack[:-1]


def scope_cycle_safe(owns: dict[str, str]) -> bool:
    color: dict[str, int] = {}

    def dfs(n: str) -> bool:
        color[n] = 1
        p = owns.get(n)
        if p is not None:
            state = color.get(p, 0)
            if state == 1:
                return False
            if state == 0 and not dfs(p):
                return False
        color[n] = 2
        return True

    for node in owns:
        if color.get(node, 0) == 0 and not dfs(node):
            return False
    return True


def restore_on_exit(stack: list[str], target_depth: int) -> list[str]:
    if target_depth < 0:
        return []
    return stack[:target_depth] if len(stack) >= target_depth else list(stack)
