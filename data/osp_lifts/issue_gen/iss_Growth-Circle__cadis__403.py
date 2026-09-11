"""Agent parent-chain depth walk with cycle guard.

The cadis runtime records each agent with an optional ``parent_agent_id``.
``agent_depth`` chases that linked list to compute lineage depth. Recovered
state files are trusted verbatim, so two mutually-parented records (or a
self-parent) made the pointer chase spin forever while holding the runtime
mutex -- the first spawn after a daemon restart wedged the whole process.
The remediation tracks visited ids and caps iterations slightly above
``MAX_CHAIN``, breaking the loop and exposing the offending chain.
Ref: Growth-Circle/cadis#403
"""

MAX_CHAIN = 64  # cap slightly above max_depth, per the fix note


def load_agents(parents):
    """``parents``: {agent_id: parent_id or None}; returns the registry."""
    return {"parents": dict(parents)}


def _walk(reg, aid):
    """Chain of ids starting at ``aid``; stops at root, unknown parent,
    revisit, or cap. Returns (chain, revisit_id or None)."""
    chain = []
    seen = set()
    cur = aid
    while cur is not None and cur in reg["parents"]:
        if cur in seen:
            return chain, cur
        if len(chain) >= MAX_CHAIN:
            return chain, None
        seen.add(cur)
        chain.append(cur)
        cur = reg["parents"][cur]
    return chain, None


def agent_depth(reg, aid):
    """Number of parent hops from ``aid`` to its chain end (root, dangling
    parent, or loop point). Unknown agent id yields 0."""
    chain, _ = _walk(reg, aid)
    return max(len(chain) - 1, 0)


def chain_of(reg, aid):
    """Lineage ids in walk order ``[aid, parent, ...]``; empty when unknown."""
    chain, _ = _walk(reg, aid)
    return list(chain)


def cycle_in(reg, aid):
    """Ids of the offending parent cycle (starting at the repeated id), or
    None when the chain is acyclic."""
    chain, hit = _walk(reg, aid)
    if hit is None:
        return None
    return chain[chain.index(hit):]
