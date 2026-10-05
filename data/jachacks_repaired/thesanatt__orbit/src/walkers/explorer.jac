# Explorer walker — random walks biased toward weak edges to discover
# hidden connections and reinforce traversed edges (spaced repetition).

import time;
import random;
import math;

import from graph.nodes { Concept, Insight }
import from graph.edges { sourced_from }
import from ai.synthesize { generate_insight }

def pick_start_node(concepts: list) -> any {
    if len(concepts) == 0 {
        return None;
    }
    now = time.time();
    weights: list = [];
    for c in concepts {
        recency_bonus = math.exp(-(now - c.created_at) / 86400.0) if c.created_at > 0 else 0.1;
        w = c.importance + 0.3 * recency_bonus;
        weights.append(max(w, 0.01));
    }
    return random.choices(concepts, weights=weights, k=1)[0];
}

# Inverse-strength weighting: weaker edges = higher selection probability
def pick_weak_neighbor(current_node: any, neighbors: list) -> tuple {
    if len(neighbors) == 0 {
        return (None, None);
    }
    edge_info: list = [];
    for n in neighbors {
        edge_info.append((n, 0.5));
    }
    weights: list = [];
    for (n, strength) in edge_info {
        inv_weight = 1.0 / (strength + 0.05);
        weights.append(inv_weight);
    }
    chosen = random.choices([ei[0] for ei in edge_info], weights=weights, k=1)[0];
    chosen_strength = 0.5;
    for (n, s) in edge_info {
        if n is chosen {
            chosen_strength = s;
            break;
        }
    }
    return (chosen, chosen_strength);
}

# Traversed edges get a small strength boost (spaced repetition)
def reinforce_edge(e: any) -> None {
    e.last_reinforced = time.time();
    e.reinforcement_count = e.reinforcement_count + 1;
    e.strength = min(e.strength + 0.02, 1.0);
}


walker Explorer {
    has max_hops: int = 6;
    has min_confidence: float = 0.5;

    has traversal_path: list = [];
    has path_descriptions: list = [];
    has path_domains: list = [];
    has discoveries: list = [];
    has visited_ids: list = [];
    has hops_taken: int = 0;
    has start_concept: str = "";

    can begin with Root entry {
        concepts = [-->][?:Concept];
        if len(concepts) == 0 {
            report {
                "status": "empty_graph",
                "traversal_path": [],
                "discoveries": [],
                "hops_taken": 0
            };
            disengage;
        }
        starter = pick_start_node(concepts);
        if starter is not None {
            visit (starter as Concept);
        } else {
            report {
                "status": "no_start",
                "traversal_path": [],
                "discoveries": [],
                "hops_taken": 0
            };
            disengage;
        }
    }

    can explore with Concept entry {
        self.traversal_path.append(here.name);
        self.path_descriptions.append(here.description);
        self.path_domains.append(here.domain);
        self.visited_ids.append(here.__jac__.id);
        here.access_count += 1;
        here.last_accessed = time.time();
        self.hops_taken += 1;

        if self.hops_taken == 1 {
            self.start_concept = here.name;
        }

        for e in ([edge <-->] as list) {
            if hasattr(e, "last_reinforced") {
                reinforce_edge(e);
            }
        }

        if self.hops_taken >= self.max_hops {
            self._try_generate_insight(here);
            report {
                "status": "complete",
                "traversal_path": self.traversal_path,
                "path_domains": self.path_domains,
                "discoveries": self.discoveries,
                "hops_taken": self.hops_taken
            };
            disengage;
        }

        neighbors = [-->][?:Concept];
        unvisited: list = [];
        for n in neighbors {
            if n.__jac__.id not in self.visited_ids {
                unvisited.append(n);
            }
        }
        candidates = unvisited if len(unvisited) > 0 else neighbors;

        if len(candidates) == 0 {
            self._try_generate_insight(here);
            report {
                "status": "dead_end",
                "traversal_path": self.traversal_path,
                "path_domains": self.path_domains,
                "discoveries": self.discoveries,
                "hops_taken": self.hops_taken
            };
            disengage;
        }

        (next_node, _) = pick_weak_neighbor(here, candidates);
        if next_node is not None {
            visit next_node;
        } else {
            report {
                "status": "no_next",
                "traversal_path": self.traversal_path,
                "discoveries": self.discoveries,
                "hops_taken": self.hops_taken
            };
            disengage;
        }
    }

    def _try_generate_insight(end_node: Concept) -> None {
        if len(self.traversal_path) < 3 {
            return;
        }
        if self.traversal_path[0] == self.traversal_path[-1] {
            return;
        }

        insight_result = generate_insight(
            start_concept=self.traversal_path[0],
            end_concept=end_node.name,
            path=self.traversal_path,
            path_descriptions=self.path_descriptions
        );

        if insight_result.confidence >= self.min_confidence {
            new_insight = Insight(
                title=insight_result.title,
                description=insight_result.description,
                confidence=insight_result.confidence,
                path=self.traversal_path,
                generated_at=time.time()
            );
            root ++> new_insight;
            new_insight +>:sourced_from(relevance=0.9, excerpt=""):+> end_node;

            discovery = {
                "title": insight_result.title,
                "description": insight_result.description,
                "confidence": insight_result.confidence,
                "analogy": insight_result.analogy,
                "path": self.traversal_path,
                "domains_crossed": list(set(self.path_domains))
            };
            self.discoveries.append(discovery);
        }
    }
}
