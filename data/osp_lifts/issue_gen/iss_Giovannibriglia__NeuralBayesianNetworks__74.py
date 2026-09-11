"""Topological node-role profiling for benchmark query selection.

Giovannibriglia/NeuralBayesianNetworks#74: benchmark queries picked uniformly
at random are dominated by easy peripheral nodes; the selection policy needs
topological roles of the DAG. The profiler hand-rolls adjacency lists and
recursive descents to compute, per node, its Markov blanket (parents,
children, co-parents) and its descendant closure. Observable results are
sets and counts: blanket sizes, descendant counts, and the hub/terminal
node selections derived from them with deterministic tie-breaks.
"""


def build_dag(nodes, edges):
    """Adjacency dict of parent -> [children] from BN (parent, child) pairs."""
    dag = {n: [] for n in nodes}
    for parent, child in edges:
        if child in dag and parent in dag:
            dag[parent].append(child)
    return dag


def parents_of(dag, node):
    return sorted(p for p, kids in dag.items() if node in kids)


def children_of(dag, node):
    return sorted(dag.get(node, []))


def markov_blanket(dag, node):
    """Parents + children + co-parents of ``node`` (sorted, minus itself)."""
    if node not in dag:
        return []
    blanket = set(parents_of(dag, node)) | set(children_of(dag, node))
    for child in children_of(dag, node):
        blanket.update(parents_of(dag, child))
    blanket.discard(node)
    return sorted(blanket)


def _descendant_count(dag, node):
    seen = set()
    stack = list(dag.get(node, []))
    while stack:
        cur = stack.pop()
        if cur in seen or cur == node:
            continue
        seen.add(cur)
        stack.extend(dag.get(cur, []))
    return len(seen)


def role_profile(dag):
    """Per-node (blanket_size, descendant_count), sorted by node name.

    Cycles terminate via the visited sets inside each traversal.
    """
    out = []
    for node in sorted(dag):
        out.append((node, len(markov_blanket(dag, node)),
                    _descendant_count(dag, node)))
    return out


def hub_nodes(dag, k):
    """Top-k nodes by Markov-blanket cardinality (ties: name ascending)."""
    ranked = sorted(dag, key=lambda n: (-len(markov_blanket(dag, n)), n))
    return ranked[:k]


def terminal_nodes(dag, k):
    """k nodes with the fewest descendants (ties: name ascending).

    These are the "long propagation path, sparse evidence reach" nodes the
    likelihood-weighted sampler struggles with.
    """
    ranked = sorted(dag, key=lambda n: (_descendant_count(dag, n), n))
    return ranked[:k]


def allocate_queries(budget):
    """Deterministic role split: 30% hubs / 25% cuts+random reserve.

    Returns (hubs_budget, terminals_budget, reserve) floor-rounded with the
    remainder pushed to the uniform-random reserve bucket.
    """
    hubs = budget * 30 // 100
    terminals = budget * 25 // 100
    reserve = budget - hubs - terminals
    return (hubs, terminals, reserve)
