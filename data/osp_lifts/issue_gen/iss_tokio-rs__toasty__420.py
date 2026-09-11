"""tokio-rs/toasty#420: Missing Use Case: Tree / Recursive Queries

Missing Use Case: Tree / Recursive Queries

 Machinery: adjacency dict, visited_set, queue/stack loops.
"""

from collections import deque

def build_graph(nodes, edges):
    adj = {n: [] for n in nodes}
    for a,b in edges:
        if a in adj and b in adj:
            adj[a].append(b)
    return adj

def reachable(graph, start):
    if start not in graph:
        return []
    seen=set(); q=[start]; out=set(); visited=set([start])
    while q:
        cur=q.pop(0)
        for nb in graph.get(cur, []):
            if nb in visited: continue
            visited.add(nb); out.add(nb); q.append(nb)
    return sorted(out)

def has_cycle(graph):
    visited=set(); rec=set()
    def dfs(v):
        visited.add(v); rec.add(v)
        for nb in graph.get(v, []):
            if nb not in visited:
                if dfs(nb): return True
            elif nb in rec: return True
        rec.remove(v); return False
    for n in graph:
        if n not in visited:
            if dfs(n): return True
    return False

def downstream(graph, seeds):
    seed_set={s for s in seeds if s in graph}; q=[]; 
    for s in seed_set: q.extend(graph.get(s, []))
    out=set(); visited=set()
    while q:
        cur=q.pop(0)
        if cur in visited: continue
        visited.add(cur)
        if cur in seed_set: continue
        out.add(cur)
        for nb in graph.get(cur, []):
            if nb not in visited: q.append(nb)
    return sorted(out)
