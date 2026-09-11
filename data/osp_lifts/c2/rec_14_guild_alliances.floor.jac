"""Guild alliance registry for an MMO server.

Guilds sign non-aggression pacts; the pact web is an adjacency dict of
guild tag -> list of allied guild tags. Two functions answer diplomatic
queries with a deque flood over allies.
"""
import from collections { deque }
"""Adjacency dict; pacts are undirected (tag_a, tag_b) pairs."""
def build_league(tags: Any, pacts: Any) -> object {
    net = {t: [] for t in tags};
    for (a, b) in pacts {
        net[a].append(b);
        net[b].append(a);
    }
    return net;
}
"""Every guild in ``tag``'s alliance bloc, including itself (sorted)."""
def allies_of(net: Any, tag: Any) -> object {
    if (tag not in net) {
        return [];
    }
    seen = {tag};
    queue = deque([tag]);
    while queue {
        cur = queue.popleft();
        for nbr in net[cur] {
            if (nbr not in seen) {
                seen.add(nbr);
                queue.append(nbr);
            }
        }
    }
    return sorted(seen);
}
"""True when ``tag_b`` sits anywhere inside ``tag_a``'s pact web."""
def allied_with(net: Any, tag_a: Any, tag_b: Any) -> object {
    if ((tag_a not in net) or (tag_b not in net)) {
        return False;
    }
    seen = {tag_a};
    queue = deque([tag_a]);
    while queue {
        cur = queue.popleft();
        if (cur == tag_b) {
            return True;
        }
        for nbr in net[cur] {
            if (nbr not in seen) {
                seen.add(nbr);
                queue.append(nbr);
            }
        }
    }
    return False;
}

