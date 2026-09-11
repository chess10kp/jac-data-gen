"""borglab/GTDynamics#435 — immutable compiled kinematic traversal."""

from __future__ import annotations

from collections import deque


class KinematicPlan:
    def __init__(
        self,
        order: list[str],
        parent: dict[str, str | None],
        offsets: dict[str, float],
    ) -> None:
        self.order = order
        self.parent = parent
        self.offsets = offsets


def compile_traversal(links: list[tuple[str, str, float]]) -> KinematicPlan:
    # links: (child, parent, fixed_offset)
    children: dict[str, list[str]] = {}
    parent: dict[str, str | None] = {}
    offsets: dict[str, float] = {}
    nodes: set[str] = set()
    for child, par, off in links:
        nodes.add(child)
        nodes.add(par)
        parent[child] = par
        offsets[child] = off
        children.setdefault(par, []).append(child)
        children.setdefault(child, [])
    roots = sorted(n for n in nodes if parent.get(n) is None)
    root = roots[0] if roots else sorted(nodes)[0]
    order: list[str] = []
    seen: set[str] = set()
    q: deque[str] = deque([root])
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        order.append(cur)
        for ch in sorted(children.get(cur, [])):
            if ch not in seen:
                q.append(ch)
    return KinematicPlan(order, parent, offsets)


def traversal_order(plan: KinematicPlan) -> list[str]:
    return list(plan.order)


def forward_positions(
    plan: KinematicPlan,
    angles: dict[str, float],
) -> dict[str, float]:
    pos: dict[str, float] = {}
    for joint in plan.order:
        par = plan.parent.get(joint)
        base = pos[par] if par is not None else 0.0
        pos[joint] = base + plan.offsets.get(joint, 0.0) + angles.get(joint, 0.0)
    return pos


def query_point_positions(
    plan: KinematicPlan,
    angles: dict[str, float],
    queries: list[tuple[str, str]],
) -> list[tuple[str, float]]:
    pos = forward_positions(plan, angles)
    out = [(label, pos[joint]) for label, joint in queries if joint in pos]
    return sorted(out)
