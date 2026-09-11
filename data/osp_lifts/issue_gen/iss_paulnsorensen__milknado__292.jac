"""Harvest summary projector with bounded, deterministic traversal.

paulnsorensen/milknado#292 lifted to OSP: goal-tree entries become GoalNode
archetypes and subtree membership becomes typed Contains edges. The unvisited
descendant walk becomes a flooding walker whose expanded map guarantees each
node is counted at most once under shared or cyclic topology; normalization
(strip, omit blanks, sort, dedupe, per-result and total-size caps) stays in
the facade as domain formatting logic.
"""
glob MAX_RESULTS: int = 1000;

node GoalNode {
    has nid: str;
    has deposit: str = "";
}
edge Contains {}

obj HarvestTree {
    has nodes: dict[str, GoalNode];

    def resolve(nid: str) -> GoalNode | None {
        return self.nodes.get(nid);
    }
}

obj HarvestSummary {
    has summaries: list[str];
    has truncated_results: bool;
    has truncated_size: bool;
}

"""Deterministic fresh-graph builder; creation order = fixture order."""
def build_tree(nodes: list[tuple[str, str]], edges: list[tuple[str, str]]) -> HarvestTree {
    t = HarvestTree(nodes={});
    for (nid, text) in nodes {
        n = GoalNode(nid=nid, deposit=text);
        root ++> n;
        t.nodes[nid] = n;
    }
    for (parent, child) in edges {
        p = t.nodes.get(parent);
        c = t.nodes.get(child);
        if p is not None and c is not None {
            p +>:Contains:+> c;
        }
    }
    return t;
}

walker CollectSubtree {
    has claimed: dict[str, bool] = {};
    has collected: list[str] = [];

    can step with GoalNode entry {
        if here.nid in self.claimed {
            skip;
        }
        self.claimed[here.nid] = True;
        self.collected.append(here.nid);
        visit [->:Contains:->];
    }
}

def _normalize(t: HarvestTree, goal: str, max_total: int) -> HarvestSummary {
    st = t.resolve(goal);
    if st is None {
        return HarvestSummary(summaries=[], truncated_results=False,
                              truncated_size=False);
    }
    w = st spawn CollectSubtree();
    texts: list[str] = [];
    for nid in w.collected {
        raw = "";
        found_node = t.resolve(nid);
        if found_node is not None {
            raw = str(found_node.deposit).strip();
        }
        if raw != "" {
            texts.append(raw);
        }
    }
    texts = sorted(texts);

    # Deduplicate sorted neighbors without a set.
    uniq: list[str] = [];
    prev: str | None = None;
    for txt in texts {
        if prev is None or txt != prev {
            uniq.append(txt);
        }
        prev = txt;
    }

    truncated_results = len(uniq) > MAX_RESULTS;
    kept: list[str] = [];
    used = 0;
    truncated_size = False;
    bounded: list[str] = uniq;
    if len(bounded) > MAX_RESULTS {
        bounded = bounded[:MAX_RESULTS];
    }
    for txt in bounded {
        cost = len(txt);
        if len(kept) > 0 {
            cost += 1;
        }
        if used + cost > max_total {
            truncated_size = True;
            break;
        }
        kept.append(txt);
        used += cost;
    }
    return HarvestSummary(summaries=kept, truncated_results=truncated_results,
                          truncated_size=truncated_size);
}

"""Project the goal subtree into a bounded, deterministic summary."""
def harvest(t: HarvestTree, goal: str, max_total: int = 4096) -> HarvestSummary {
    return _normalize(t, goal, max_total);
}
