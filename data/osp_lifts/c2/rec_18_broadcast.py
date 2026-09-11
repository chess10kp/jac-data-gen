"""Cluster broadcast planner: hop budget per server.

The cluster is an adjacency dict of hostname -> list of peer hostnames
(links are undirected). A config push from one origin fans out level by
level; the planner records how many hops each server waits.
"""
from collections import deque


def build_cluster(hosts, links):
    """Adjacency dict; links are undirected (host_a, host_b) pairs."""
    net = {h: [] for h in hosts}
    for a, b in links:
        net[a].append(b)
        net[b].append(a)
    return net


def broadcast_plan(net, origin):
    """hostname -> hop count at which it receives the push."""
    if origin not in net:
        return {}
    hops = {origin: 0}
    frontier = [origin]
    depth = 0
    while frontier:
        depth += 1
        nxt_frontier = []
        for cur in frontier:
            for peer in net[cur]:
                if peer not in hops:
                    hops[peer] = depth
                    nxt_frontier.append(peer)
        frontier = nxt_frontier
    return hops


def propagation_time(net, origin):
    """Hops until the whole reachable cluster is updated (0 if alone, -1
    when the origin is unknown)."""
    plan = broadcast_plan(net, origin)
    if not plan:
        return -1 if origin not in net else 0
    return max(plan.values())
