"""SARIF directory export: each referenced finding emitted once.

A directory export recursively loads every report file, while suite and
matrix aggregates ALSO import the child reports they reference. Parent
expansion and recursive discovery previously operated independently with
no shared visited set, so a child run referenced by two suites -- or also
discovered directly on disk -- had its findings exported twice, inflating
Code Scanning result counts. The fix tracks canonical report sources in
one shared visited set across every expansion path.
Ref: richinmrudul/agentguard#182
"""


def load_reports(reports, references):
    """``reports``: {report_id: [finding, ...]}. ``references``:
    (parent_id, child_id) pairs -- parent embeds child's findings."""
    return {"reports": dict(reports), "refs": _index(reports, references)}


def _index(reports, references):
    refs = {k: [] for k in reports}
    for parent, child in references:
        refs[parent].append(child)
    return refs


def export_findings(src, root_ids):
    """Findings of every report reachable from any root, deduplicated.

    Returns a sorted list of ``(report_id, finding)`` pairs; each report
    contributes its findings exactly once no matter how many expansion
    paths reach it.
    """
    visited = set()
    out = []
    for root in sorted(root_ids):
        stack = [root]
        if root in visited:
            continue
        pending = []
        while stack:
            cur = stack.pop()
            if cur in visited or cur not in src["reports"]:
                continue
            visited.add(cur)
            for finding in src["reports"][cur]:
                out.append((cur, finding))
            pending.extend(src["refs"].get(cur, []))
        stack = pending
        # continue draining through referenced children
        while stack:
            cur = stack.pop()
            if cur in visited or cur not in src["reports"]:
                continue
            visited.add(cur)
            for finding in src["reports"][cur]:
                out.append((cur, finding))
            stack.extend(src["refs"].get(cur, []))
    return sorted(out)


def report_count(src, root_ids):
    """Distinct reports contributing to the export."""
    visited = set()
    stack = list(root_ids)
    while stack:
        cur = stack.pop()
        if cur in visited or cur not in src["reports"]:
            continue
        visited.add(cur)
        stack.extend(src["refs"].get(cur, []))
    return len(visited)
