# Consolidator walker — cluster summarization, edge decay detection,
# and orphan detection across the knowledge graph.

import time;
import math;

import from graph.nodes { Concept, Insight }
import from graph.edges { builds_upon }
import from ai.synthesize { generate_cluster_summary }


def build_adjacency(concept_nodes: list, neighbor_map: dict) -> dict {
    adjacency: dict = {};
    for node_name in neighbor_map {
        adjacency[node_name] = set(neighbor_map[node_name]);
    }
    return adjacency;
}


# Greedy clustering: grow clusters from seeds by neighbor overlap
def find_dense_clusters(
    concept_names: list,
    adjacency: dict,
    min_cluster_size: int = 3,
    overlap_threshold: float = 0.3
) -> list {
    clusters: list = [];
    assigned: set = set();

    for name in concept_names {
        if name in assigned or name not in adjacency {
            continue;
        }
        cluster: list = [name];
        cluster_set: set = {name};

        neighbors = adjacency.get(name, set());
        for neighbor in neighbors {
            if neighbor in assigned or neighbor not in adjacency {
                continue;
            }
            neighbor_adj = adjacency.get(neighbor, set());
            shared = len(neighbors & neighbor_adj);
            total = max(len(neighbors | neighbor_adj), 1);
            if shared / total >= overlap_threshold or shared >= 2 {
                cluster.append(neighbor);
                cluster_set.add(neighbor);
            }
        }

        if len(cluster) >= min_cluster_size {
            for c in cluster {
                assigned.add(c);
            }
            clusters.append(cluster);
        }
    }

    return clusters;
}


walker Consolidator {
    has decay_threshold: float = 0.2;
    has min_cluster_size: int = 3;
    has min_neighbors: int = 2;
    has max_cluster_concepts: int = 20;

    has traversal_path: list = [];
    has concepts_visited: list = [];
    has concept_data: dict = {};
    has neighbor_map: dict = {};
    has weak_edges_found: list = [];
    has orphans_found: list = [];
    has summaries_created: list = [];
    has edges_inspected: int = 0;
    has visited_ids: list = [];

    can begin with Root entry {
        concepts = [-->][?:Concept];
        if len(concepts) == 0 {
            report {
                "status": "empty_graph",
                "traversal_path": [],
                "concepts_analyzed": 0,
                "weak_edges": [],
                "orphans": [],
                "summaries_created": []
            };
            disengage;
        }
        visit concepts;
    }

    can analyze with Concept entry {
        node_id = here.__jac__.id;
        if node_id in self.visited_ids {
            return;
        }
        self.visited_ids.append(node_id);

        self.traversal_path.append(here.name);
        self.concepts_visited.append(here.name);
        here.access_count += 1;
        here.last_accessed = time.time();

        self.concept_data[here.name] = {
            "description": here.description,
            "domain": here.domain,
            "importance": here.importance,
            "depth": here.depth
        };

        neighbor_names: list = [];
        outgoing_edges: list = [edge <-->];
        for e in outgoing_edges {
            self.edges_inspected += 1;

            if hasattr(e, "strength") {
                if e.strength < self.decay_threshold {
                    target_name = "";
                    if hasattr(e, "relationship") {
                        target_name = e.relationship;
                    }
                    self.weak_edges_found.append({
                        "from": here.name,
                        "edge_type": type(e).__name__,
                        "strength": round(e.strength, 3),
                        "relationship": target_name,
                        "last_reinforced": getattr(e, "last_reinforced", 0.0),
                        "message": "Connection from '" + here.name + "' is fading (strength: " + str(round(e.strength, 3)) + ")"
                    });
                }
            }
        }

        concept_neighbors = [-->][?:Concept];
        for n in concept_neighbors {
            neighbor_names.append(n.name);
        }
        incoming_neighbors = [<--][?:Concept];
        for n in incoming_neighbors {
            if n.name not in neighbor_names {
                neighbor_names.append(n.name);
            }
        }
        self.neighbor_map[here.name] = neighbor_names;

        total_connections = len(concept_neighbors) + len(incoming_neighbors);
        if total_connections < self.min_neighbors {
            self.orphans_found.append({
                "name": here.name,
                "domain": here.domain,
                "connections": total_connections,
                "message": "'" + here.name + "' is isolated with only " + str(total_connections) + " connection(s). Consider linking it to related concepts."
            });
        }

        unvisited: list = [];
        for n in concept_neighbors {
            if n.__jac__.id not in self.visited_ids {
                unvisited.append(n);
            }
        }
        if len(unvisited) > 0 {
            visit unvisited;
        }
    }

    can finish with Root exit {
        if len(self.concepts_visited) >= self.min_cluster_size {
            adjacency = build_adjacency(self.concepts_visited, self.neighbor_map);
            clusters = find_dense_clusters(
                self.concepts_visited,
                adjacency,
                min_cluster_size=self.min_cluster_size
            );

            for cluster in clusters {
                cluster_limited = cluster[:self.max_cluster_concepts];
                descriptions: list = [];
                for name in cluster_limited {
                    if name in self.concept_data {
                        descriptions.append(self.concept_data[name]["description"]);
                    } else {
                        descriptions.append("");
                    }
                }

                summary = generate_cluster_summary(
                    cluster_limited,
                    descriptions
                );

                insight_node = Insight(
                    title=summary.label,
                    description=summary.theme,
                    confidence=0.7,
                    path=cluster_limited,
                    generated_at=time.time()
                );

                root ++> insight_node;

                self.summaries_created.append({
                    "title": summary.label,
                    "theme": summary.theme,
                    "key_concepts": summary.key_concepts,
                    "knowledge_level": summary.knowledge_level,
                    "cluster_size": len(cluster_limited)
                });
            }
        }

        report {
            "status": "complete",
            "traversal_path": self.traversal_path,
            "concepts_analyzed": len(self.concepts_visited),
            "edges_inspected": self.edges_inspected,
            "weak_edges": self.weak_edges_found,
            "weak_edge_count": len(self.weak_edges_found),
            "orphans": self.orphans_found,
            "orphan_count": len(self.orphans_found),
            "summaries_created": self.summaries_created,
            "clusters_found": len(self.summaries_created)
        };
    }
}
