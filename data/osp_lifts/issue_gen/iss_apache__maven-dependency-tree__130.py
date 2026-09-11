"""Dependency-graph collection for ``mvn dependency:tree`` style walks.

The default collector walks the dependency graph recursively: every node
"accepts" the walk by recursing over its children (DefaultDependencyNode.
accept), so a pathological deep chain overflows the native call stack
(StackOverflowError) instead of failing gracefully. The iterative
remediation computes the same dependency closure but drives the walk with
an explicit work stack, so chains of any depth resolve without recursion.
Both walks deduplicate (an artifact already reached is not revisited) and
normalize output to sorted artifact ids, because traversal order is an
internal artifact of the walk, not part of the report contract.
Ref: apache/maven-dependency-tree#130
"""


def collect(graph, root):
    """Recursive pre-order closure walk (crashes on very deep chains).

    ``graph`` maps artifact ids to the list of artifact ids they depend
    on. Returns the sorted ids of every artifact reachable from ``root``.
    """
    seen = set()
    order = []
    _accept(root, graph, seen, order)
    return sorted(order)


def _accept(name, graph, seen, order):
    if name in seen:
        return
    seen.add(name)
    order.append(name)
    for child in graph.get(name, []):
        _accept(child, graph, seen, order)


def collect_iter(graph, root):
    """Iterative post-fix walk: explicit work stack, no recursion, any depth.

    Returns the same sorted dependency closure as ``collect``.
    """
    seen = set()
    order = []
    stack = [root]
    while stack:
        name = stack.pop()
        if name in seen:
            continue
        seen.add(name)
        order.append(name)
        for child in reversed(graph.get(name, [])):
            stack.append(child)
    return sorted(order)


def count_nodes(graph, root):
    """Number of artifacts in the dependency closure of ``root``."""
    return len(collect_iter(graph, root))
