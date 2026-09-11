"""b-at-neu/port#52 — Pipeline checkout branch visibility and workflow dependency reach."""

from __future__ import annotations

_REQUIRED: tuple[str, ...] = (
    ".claude/port.config.json",
    ".claude/settings.json",
)


class PipelineHandle:
    def __init__(self) -> None:
        self.branches: dict[str, bool] = {}
        self.parent_of: dict[str, str | None] = {}
        self.artifacts: dict[str, list[str]] = {}
        self.allow_flags: dict[str, bool] = {}
        self.tickets: dict[str, bool] = {}
        self.blocked_by: dict[str, list[str]] = {}


def load_pipeline(
    branch_ids: list[str],
    parent_edges: list[tuple[str, str]],
    branch_artifacts: list[tuple[str, list[str]]],
    branch_allow: list[tuple[str, bool]],
    ticket_ids: list[str],
    depends_edges: list[tuple[str, str]],
) -> PipelineHandle:
    p = PipelineHandle()
    for b in branch_ids:
        p.branches[b] = True
        p.parent_of[b] = None
        p.artifacts[b] = []
        p.allow_flags[b] = False
    for child, parent in parent_edges:
        if child not in p.branches or parent not in p.branches:
            raise KeyError("unknown branch")
        p.parent_of[child] = parent
    for branch, arts in branch_artifacts:
        if branch not in p.branches:
            raise KeyError("unknown branch")
        p.artifacts[branch] = list(arts)
    for branch, ok in branch_allow:
        if branch not in p.branches:
            raise KeyError("unknown branch")
        p.allow_flags[branch] = bool(ok)
    for tid in ticket_ids:
        p.tickets[tid] = True
        p.blocked_by[tid] = []
    for ticket, blocker in depends_edges:
        if ticket not in p.tickets or blocker not in p.tickets:
            raise KeyError("unknown ticket")
        p.blocked_by[ticket].append(blocker)
    return p


def branches_carrying(pipeline: PipelineHandle, artifact: str) -> list[str]:
    return sorted(
        b for b in pipeline.branches if artifact in pipeline.artifacts.get(b, [])
    )


def preflight_checkout(pipeline: PipelineHandle, checkout_branch: str) -> list[str]:
    if checkout_branch not in pipeline.branches:
        return ["unknown checkout branch"]
    msgs: list[str] = []
    on_disk = pipeline.artifacts.get(checkout_branch, [])
    for req in _REQUIRED:
        if req not in on_disk:
            carriers = branches_carrying(pipeline, req)
            hint = f"; present on {', '.join(carriers)}" if carriers else ""
            msgs.append(f"missing {req} on {checkout_branch}{hint}")
    if (
        ".claude/settings.json" in on_disk
        and not pipeline.allow_flags.get(checkout_branch, False)
    ):
        msgs.append(
            f"missing permissions.allow in .claude/settings.json on {checkout_branch}"
        )
    return sorted(msgs)


def blocker_closure(pipeline: PipelineHandle, ticket: str) -> list[str]:
    if ticket not in pipeline.tickets:
        return []
    reached: list[str] = []
    claimed: dict[str, bool] = {}
    bootstrapped = False

    def step(here: str) -> None:
        nonlocal bootstrapped
        if here == ticket and not bootstrapped:
            bootstrapped = True
            for blk in sorted(pipeline.blocked_by.get(here, [])):
                step(blk)
            return
        if here in claimed:
            return
        claimed[here] = True
        reached.append(here)
        for blk in sorted(pipeline.blocked_by.get(here, [])):
            step(blk)

    step(ticket)
    return sorted(reached)


def ready_tickets(
    pipeline: PipelineHandle, completed: list[str] | None = None
) -> list[str]:
    done = {c: True for c in (completed or [])}
    out: list[str] = []
    for tid in sorted(pipeline.tickets):
        if tid in done:
            continue
        if all(b in done for b in pipeline.blocked_by.get(tid, [])):
            out.append(tid)
    return out


def dependency_paths(
    pipeline: PipelineHandle,
    ticket: str,
    blocker: str,
    *,
    max_depth: int = 12,
) -> list[list[str]]:
    if ticket not in pipeline.tickets or blocker not in pipeline.tickets:
        return []
    paths: list[list[str]] = []

    def walk(here: str, trail: list[str], on_path: dict[str, bool]) -> None:
        if here in on_path:
            return
        nt = trail + [here]
        nop = {**on_path, here: True}
        if len(nt) > max_depth:
            return
        if here == blocker:
            paths.append(list(nt))
            return
        for blk in sorted(pipeline.blocked_by.get(here, [])):
            walk(blk, nt, nop)

    walk(ticket, [], {})
    return sorted(paths)


def lineage_paths(
    pipeline: PipelineHandle,
    from_branch: str,
    to_branch: str,
    *,
    max_depth: int = 12,
) -> list[list[str]]:
    if from_branch not in pipeline.branches or to_branch not in pipeline.branches:
        return []
    parent_adj: dict[str, list[str]] = {}
    for branch, parent in pipeline.parent_of.items():
        if parent is not None:
            parent_adj.setdefault(branch, []).append(parent)
    paths: list[list[str]] = []

    def walk(here: str, trail: list[str], on_path: dict[str, bool]) -> None:
        if here in on_path:
            return
        nt = trail + [here]
        nop = {**on_path, here: True}
        if len(nt) > max_depth:
            return
        if here == to_branch:
            paths.append(list(nt))
            return
        for parent in sorted(parent_adj.get(here, [])):
            walk(parent, nt, nop)

    walk(from_branch, [], {})
    return sorted(paths)
