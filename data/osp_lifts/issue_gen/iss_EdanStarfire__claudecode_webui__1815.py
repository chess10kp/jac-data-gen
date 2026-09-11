"""Holder-chain analysis for transitive dependency security alerts.

All 34 open Dependabot alerts in this project flag packages that never
appear in ``[project.dependencies]``: every one is transitive, pulled in
by some direct dependency's own constraint tree. There is no one-line
pin to bump for any of them -- before an upgrade can be planned you have
to know WHICH direct dependency chain holds each flagged package back,
because the fix is either a forced relock (when the existing direct
constraints already permit the patched version) or a bump of the direct
dependency whose own constraint is doing the holding.

The lock graph is kept as a package -> deps adjacency (the reserved key
``"root"`` lists the project's direct dependencies). Enumerating the
holder chains is a simple-path search: DFS from every direct dependency
with a visited set on the CURRENT PATH (lock graphs are near-DAGs but
can contain cycles, and a package must never appear twice in one
chain). Every path that reaches the flagged package is one holder
chain; chains are returned sorted, and an unreachable package yields
an empty list.
Ref: EdanStarfire/claudecode_webui#1815
"""


def holder_chains(lock, target):
    """All simple paths from the root's direct dependencies to ``target``.

    ``lock`` maps package name -> list of packages it depends on; the
    reserved key ``"root"`` lists the project's direct dependencies.
    Returns a sorted list of chains; each chain is ``[root_dep, ...,
    target]`` (a chain of length 1 means the target is itself a direct
    dependency). Returns ``[]`` when the target is unreachable.
    """
    chains = []
    for direct in lock.get("root", []):
        _descend(direct, lock, target, [direct], chains)
    chains.sort()
    return chains


def _descend(name, lock, target, path, out):
    """DFS over the adjacency, one branch per simple path."""
    if name == target:
        out.append(list(path))  # one holder chain complete
        return
    for dep in lock.get(name, []):
        if dep in path:
            continue  # simple paths only: no package twice in one chain
        path.append(dep)
        _descend(dep, lock, target, path, out)
        path.pop()
