"""Packaging dependency DAG and install-workflow reachability for hdrshot.

TheBigSasha/windows_hdr_screenshot#15 — pyproject/requirements drift,
optional gui/heic extras, fragile run.bat sentinel chain, bundle closure.
"""

from collections import deque


def build_dep_graph(packages, depends):
  # package -> direct dependencies (adjacency forward: consumer -> dep)
    adj = {p: [] for p in packages}
    for pkg, dep in depends:
        if pkg in adj and dep in adj:
            adj[pkg].append(dep)
    return adj


def transitive_deps(adj, root):
    if root not in adj:
        return []
    seen = {root}
    found = set()
    queue = deque(adj[root])
    while queue:
        cur = queue.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        found.add(cur)
        queue.extend(adj.get(cur, []))
    return sorted(found)


def build_workflow(steps, transitions):
    adj = {s: [] for s in steps}
    for src, dst in transitions:
        if src in adj and dst in adj:
            adj[src].append(dst)
    return adj


def is_reachable(adj, start, goal):
    if start not in adj or goal not in adj:
        return False
    seen = {start}
    queue = deque([start])
    while queue:
        cur = queue.popleft()
        if cur == goal:
            return True
        for nxt in adj.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return False


def paths_between(adj, source, target, max_depth=12):
    if source not in adj or target not in adj:
        return []
    out = []
    stack = [(source, [source])]
    while stack:
        node, trail = stack.pop()
        if node == target:
            out.append(trail)
            continue
        if len(trail) >= max_depth:
            continue
        for nxt in adj.get(node, []):
            if nxt not in trail:
                stack.append((nxt, trail + [nxt]))
    return sorted(out)


def version_drift(declarations):
    merged = {}
    for source in sorted(declarations):
        for pkg, ver in declarations[source].items():
            merged.setdefault(pkg, set()).add(ver)
    return sorted(pkg for pkg, vers in merged.items() if len(vers) > 1)


def launch_allowed(workflow, completed, launch_step="launch_gui"):
  # run.bat fix: sentinel must exist before GUI launch
    if launch_step not in workflow:
        return False
    if "install_sentinel" not in completed:
        return False
    preds = [a for a in workflow if launch_step in workflow[a]]
    return all(p in completed for p in preds)
