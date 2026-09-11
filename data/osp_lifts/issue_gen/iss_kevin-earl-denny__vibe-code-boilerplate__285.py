"""kevin-earl-denny/vibe-code-boilerplate#285 — Ticket blocking chain highlight.

Linear tickets form a directed blocking graph. Selecting a ticket collects its
full upstream blockers and downstream blocked tickets via adjacency dict BFS.
"""

from __future__ import annotations

from collections import deque


class TicketBoard:
    def __init__(self) -> None:
        self.tickets: set[str] = set()
        self.blocks: dict[str, list[str]] = {}


def load_tickets(
    tickets: list[str],
    block_edges: list[tuple[str, str]],
) -> TicketBoard:
    board = TicketBoard()
    for tid in tickets:
        board.tickets.add(tid)
        board.blocks.setdefault(tid, [])
    for blocker, blocked in block_edges:
        if blocker in board.tickets and blocked in board.tickets:
            board.blocks.setdefault(blocker, []).append(blocked)
            board.blocks.setdefault(blocked, board.blocks.get(blocked, []))
    return board


def _reverse_blocks(board: TicketBoard) -> dict[str, list[str]]:
    rev: dict[str, list[str]] = {t: [] for t in board.tickets}
    for src, dsts in board.blocks.items():
        for dst in dsts:
            rev.setdefault(dst, []).append(src)
    return rev


def highlight_chain(board: TicketBoard, ticket_id: str) -> list[str]:
    if ticket_id not in board.tickets:
        return []
    rev = _reverse_blocks(board)
    seen: set[str] = {ticket_id}
    up_q: deque[str] = deque([ticket_id])
    while up_q:
        cur = up_q.popleft()
        for blk in rev.get(cur, []):
            if blk not in seen:
                seen.add(blk)
                up_q.append(blk)
    down_q: deque[str] = deque([ticket_id])
    while down_q:
        cur = down_q.popleft()
        for nxt in board.blocks.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                down_q.append(nxt)
    return sorted(seen)
