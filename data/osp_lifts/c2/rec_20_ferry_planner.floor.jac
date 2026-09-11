"""Ferry network planner for an archipelago.

Islands are nodes; seasonal ferry lines are undirected adjacency entries
(island -> list of reachable islands). Planners group islands into
connected clusters with a list-as-stack walk, then answer point-to-point
questions from those groups.
"""
import from collections { deque }
"""Adjacency dict; routes are undirected (a, b) pairs."""
def build_ferryweb(islands: Any, routes: Any) -> object {
    web = {i: [] for i in islands};
    for (a, b) in routes {
        web[a].append(b);
        web[b].append(a);
    }
    return web;
}
"""Connected clusters; each group sorted inside, groups ordered by
    the fixture order of their first-discovered island."""
def island_groups(web: Any) -> object {
    claimed = `set();
    groups = [];
    for start in web {
        if (start in claimed) {
            continue;
        }
        group = {start};
        queue = deque([start]);
        while queue {
            cur = queue.popleft();
            for nbr in web[cur] {
                if (nbr not in group) {
                    group.add(nbr);
                    queue.append(nbr);
                }
            }
        }
        claimed |= group;
        groups.append(sorted(group));
    }
    return groups;
}

"""True when a passenger can hop from ``src`` to ``dst``."""
def can_travel(web: Any, src: Any, dst: Any) -> object {
    if ((src not in web) or (dst not in web)) {
        return False;
    }
    seen = {src};
    stack = [src];
    while stack {
        cur = stack.pop();
        if (cur == dst) {
            return True;
        }
        for nbr in web[cur] {
            if (nbr not in seen) {
                seen.add(nbr);
                stack.append(nbr);
            }
        }
    }
    return False;
}

