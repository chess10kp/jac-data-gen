"""Neighborhood portal friend-circle queries.

Members of a housing co-op register on the portal; mutual friendships form an
undirected graph keyed by member id. A "friend circle" is a connected
component of that graph. Traversal is a classic adjacency-dict BFS with a
deque frontier and a visited set.
"""
import from collections { deque }
"""Adjacency dict: member id -> list of friend ids."""
def build_network(members: Any, friendships: Any) -> object {
    graph = {m: [] for m in members};
    for (a, b) in friendships {
        graph[a].append(b);
        graph[b].append(a);
    }
    return graph;
}
"""All ids in the friend circle containing ``member`` (sorted).

    Unknown ids yield an empty circle.
    """
def circle_of(graph: Any, member: Any) -> object {
    if (member not in graph) {
        return [];
    }
    seen = {member};
    queue = deque([member]);
    while queue {
        cur = queue.popleft();
        for nbr in graph[cur] {
            if (nbr not in seen) {
                seen.add(nbr);
                queue.append(nbr);
            }
        }
    }
    return sorted(seen);
}

"""Number of disjoint friend circles in the network."""
def circle_count(graph: Any) -> object {
    seen = `set();
    count = 0;
    for m in graph {
        if (m in seen) {
            continue;
        }
        count += 1;
        seen.add(m);
        queue = deque([m]);
        while queue {
            cur = queue.popleft();
            for nbr in graph[cur] {
                if (nbr not in seen) {
                    seen.add(nbr);
                    queue.append(nbr);
                }
            }
        }
    }
    return count;
}

