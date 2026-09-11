"""NobuData/ouroboros#276 — Ticket dependency cycle detection."""

from __future__ import annotations


class TicketBoard:
    def __init__(self) -> None:
        self._tickets: set[str] = set()
        self._blocks: dict[str, list[str]] = {}


def load_ticket_board(
    tickets: list[str],
    blocks: list[tuple[str, str]],
) -> TicketBoard:
    b = TicketBoard()
    for tid in tickets:
        b._tickets.add(tid)
        b._blocks.setdefault(tid, [])
    for blocker, blocked in blocks:
        if blocker in b._tickets and blocked in b._tickets:
            b._blocks.setdefault(blocked, []).append(blocker)
    return b


def has_dependency_cycle(board: TicketBoard) -> bool:
    visited: set[str] = set()
    stack: set[str] = set()

    def dfs(node: str) -> bool:
        visited.add(node)
        stack.add(node)
        for prereq in board._blocks.get(node, []):
            if prereq in stack:
                return True
            if prereq not in visited and dfs(prereq):
                return True
        stack.remove(node)
        return False

    for tid in sorted(board._tickets):
        if tid not in visited and dfs(tid):
            return True
    return False


def push_order(board: TicketBoard) -> list[str]:
    indeg: dict[str, int] = {t: 0 for t in board._tickets}
    rev: dict[str, list[str]] = {t: [] for t in board._tickets}
    for blocked in board._tickets:
        for prereq in board._blocks.get(blocked, []):
            indeg[blocked] += 1
            rev[prereq].append(blocked)
    ready = sorted(t for t in board._tickets if indeg[t] == 0)
    order: list[str] = []
    while ready:
        cur = ready.pop(0)
        order.append(cur)
        for nxt in sorted(rev.get(cur, [])):
            indeg[nxt] -= 1
            if indeg[nxt] == 0:
                ready.append(nxt)
                ready.sort()
    return order if len(order) == len(board._tickets) else []
