"""Transit planner: station reachability and fewest-stop routes.

The metro map is an adjacency dict of station -> list of neighbor stations;
route queries are deque BFS over that dict with a visited set.
"""
import from collections { deque }
"""Adjacency dict; connections are (station_a, station_b, line) triples."""
def build_metro(stations: Any, connections: Any) -> object {
    net = {s: [] for s in stations};
    for (a, b, _line) in connections {
        net[a].append(b);
        net[b].append(a);
    }
    return net;
}
"""Every station reachable from ``station``, including itself (sorted)."""
def reachable(net: Any, station: Any) -> object {
    if (station not in net) {
        return [];
    }
    seen = {station};
    queue = deque([station]);
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
"""Fewest hops between two stations; -1 if unknown or unreachable."""
def min_stops(net: Any, src: Any, dst: Any) -> object {
    if ((src not in net) or (dst not in net)) {
        return -1;
    }
    dist = {src: 0};
    queue = deque([src]);
    while queue {
        cur = queue.popleft();
        if (cur == dst) {
            return dist[cur];
        }
        for nbr in net[cur] {
            if (nbr not in dist) {
                dist[nbr] = dist[cur] + 1;
                queue.append(nbr);
            }
        }
    }
    return -1;
}

