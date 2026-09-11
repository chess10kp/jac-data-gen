"""Harvest summary projector with bounded, deterministic traversal.

paulnsorensen/milknado#292: the harvest projector walks a goal subtree and
projects a deterministic text summary. Its traversal does not track visited
node ids (shared or cyclic topology double-counts), summary order depends on
graph-return ordering, and whitespace-only deposits survive stripping as empty
entries. The hardened contract: each node visited at most once, blank deposits
omitted, per-result and total-size caps enforced after normalization, and
branch output sorted and deduplicated.
"""

MAX_RESULTS = 1000


class HarvestSummary:
    """Projected result of one subtree harvest."""

    def __init__(self, summaries, truncated_results, truncated_size):
        self.summaries = summaries                  # normalized, sorted, deduped
        self.truncated_results = truncated_results  # count cap hit
        self.truncated_size = truncated_size        # size cap hit

    def __eq__(self, other):
        return (self.summaries == other.summaries
                and self.truncated_results == other.truncated_results
                and self.truncated_size == other.truncated_size)

    def __repr__(self):
        return "HarvestSummary({!r}, {!r}, {!r})".format(
            self.summaries, self.truncated_results, self.truncated_size)


def build_tree(nodes, edges):
    """Adjacency dict; nodes are (id, deposit) pairs, edges parent->child."""
    adj = {nid: [] for nid, _ in nodes}
    deposits = {nid: text for nid, text in nodes}
    for parent, child in edges:
        if parent in adj and child in adj:
            adj[parent].append(child)
    return adj, deposits


def _collect(adj, goal):
    """Every node id in the goal subtree at most once (cycle-safe)."""
    seen = set()
    stack = [goal]
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        stack.extend(adj[cur])
    return seen


def harvest(adj, deposits, goal, max_total=4096):
    """Project the goal subtree into a bounded, deterministic summary.

    Deposits are stripped; blanks never become entries. Output is sorted and
    deduplicated, capped at MAX_RESULTS entries and ``max_total`` characters;
    caps report which bound fired.
    """
    if goal not in adj:
        return HarvestSummary([], False, False)

    entries = []
    for nid in _collect(adj, goal):
        text = str(deposits.get(nid, "")).strip()
        if text:
            entries.append(text)
    entries = sorted(set(entries))

    truncated_results = len(entries) > MAX_RESULTS
    kept = []
    used = 0
    truncated_size = False
    for text in entries[:MAX_RESULTS]:
        cost = len(text) + (1 if kept else 0)
        if used + cost > max_total:
            truncated_size = True
            break
        kept.append(text)
        used += cost
    return HarvestSummary(kept, truncated_results, truncated_size)
