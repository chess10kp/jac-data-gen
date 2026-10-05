# Cartographer walker — maps intellectual territory by domain, finds
# bridge concepts, and identifies isolated knowledge islands.

import time;

import from graph.nodes { Concept, Source, Insight, Question, Person, Project }
import from ai.synthesize { generate_cluster_summary }


walker Cartographer {
    has dense_threshold: int = 10;
    has moderate_threshold: int = 5;
    has bridge_min_domains: int = 2;

    has traversal_path: list = [];
    has visited_ids: list = [];

    has domain_concepts: dict = {};
    has concept_edge_counts: dict = {};
    has concept_domains_touched: dict = {};
    has domain_edge_pairs: dict = {};

    has total_concepts: int = 0;
    has total_sources: int = 0;
    has total_insights: int = 0;
    has total_persons: int = 0;
    has total_projects: int = 0;
    has total_questions: int = 0;
    has total_edges_seen: int = 0;

    has territories: list = [];
    has bridges: list = [];
    has islands: list = [];

    can begin with Root entry {
        visit [-->];
    }

    can map_concept with Concept entry {
        node_id = here.__jac__.id;
        if node_id in self.visited_ids {
            return;
        }
        self.visited_ids.append(node_id);

        self.traversal_path.append({
            "type": "concept",
            "name": here.name,
            "domain": here.domain
        });

        here.access_count += 1;
        here.last_accessed = time.time();
        self.total_concepts += 1;

        domain = here.domain;
        if domain not in self.domain_concepts {
            self.domain_concepts[domain] = [];
        }
        self.domain_concepts[domain].append({
            "name": here.name,
            "description": here.description,
            "importance": here.importance,
            "depth": here.depth,
            "access_count": here.access_count
        });

        neighbors = [-->][?:Concept];
        also_back = [<--][?:Concept];
        all_neighbors: list = [];
        seen_neighbor_ids: list = [];
        for n in neighbors {
            nid = n.__jac__.id;
            if nid not in seen_neighbor_ids {
                seen_neighbor_ids.append(nid);
                all_neighbors.append(n);
            }
        }
        for n in also_back {
            nid = n.__jac__.id;
            if nid not in seen_neighbor_ids {
                seen_neighbor_ids.append(nid);
                all_neighbors.append(n);
            }
        }

        edge_count = len(all_neighbors);
        self.concept_edge_counts[here.name] = edge_count;
        self.total_edges_seen += edge_count;

        domains_touched: list = [];
        for n in all_neighbors {
            n_domain = n.domain;
            if n_domain != domain and n_domain not in domains_touched {
                domains_touched.append(n_domain);
            }
            if n_domain != domain {
                pair_key = "|".join(sorted([domain, n_domain]));
                if pair_key not in self.domain_edge_pairs {
                    self.domain_edge_pairs[pair_key] = 0;
                }
                self.domain_edge_pairs[pair_key] += 1;
            }
        }
        self.concept_domains_touched[here.name] = domains_touched;

        visit [-->];
    }

    can count_source with Source entry {
        node_id = here.__jac__.id;
        if node_id in self.visited_ids {
            return;
        }
        self.visited_ids.append(node_id);
        self.total_sources += 1;
        self.traversal_path.append({
            "type": "source",
            "name": here.title
        });
        visit [-->];
    }

    can count_insight with Insight entry {
        node_id = here.__jac__.id;
        if node_id in self.visited_ids {
            return;
        }
        self.visited_ids.append(node_id);
        self.total_insights += 1;
        self.traversal_path.append({
            "type": "insight",
            "name": here.title
        });
        visit [-->];
    }

    can count_question with Question entry {
        node_id = here.__jac__.id;
        if node_id in self.visited_ids {
            return;
        }
        self.visited_ids.append(node_id);
        self.total_questions += 1;
        self.traversal_path.append({
            "type": "question",
            "name": here.text
        });
        visit [-->];
    }

    can count_person with Person entry {
        node_id = here.__jac__.id;
        if node_id in self.visited_ids {
            return;
        }
        self.visited_ids.append(node_id);
        self.total_persons += 1;
        self.traversal_path.append({
            "type": "person",
            "name": here.name
        });
        visit [-->];
    }

    can count_project with Project entry {
        node_id = here.__jac__.id;
        if node_id in self.visited_ids {
            return;
        }
        self.visited_ids.append(node_id);
        self.total_projects += 1;
        self.traversal_path.append({
            "type": "project",
            "name": here.name
        });
        visit [-->];
    }

    can finish with Root exit {
        total_nodes = (self.total_concepts + self.total_sources
                       + self.total_insights + self.total_persons
                       + self.total_projects + self.total_questions);

        for domain in self.domain_concepts {
            concepts = self.domain_concepts[domain];
            concept_names = [c["name"] for c in concepts];
            concept_descriptions = [c["description"] for c in concepts];
            concept_count = len(concepts);

            density = "sparse";
            if concept_count >= self.dense_threshold {
                density = "dense";
            } elif concept_count >= self.moderate_threshold {
                density = "moderate";
            }

            avg_importance = 0.0;
            depth_counts: dict = {"surface": 0, "intermediate": 0, "deep": 0};
            total_access = 0;
            for c in concepts {
                avg_importance += c["importance"];
                total_access += c["access_count"];
                d = c["depth"];
                if d in depth_counts {
                    depth_counts[d] += 1;
                }
            }
            avg_importance = avg_importance / concept_count if concept_count > 0 else 0.0;

            cross_connections = 0;
            connected_domains: list = [];
            for pair_key in self.domain_edge_pairs {
                if domain in pair_key.split("|") {
                    cross_connections += self.domain_edge_pairs[pair_key];
                    parts = pair_key.split("|");
                    other = parts[1] if parts[0] == domain else parts[0];
                    if other not in connected_domains {
                        connected_domains.append(other);
                    }
                }
            }

            is_island = cross_connections == 0 and concept_count > 0;

            domain_bridges: list = [];
            for c in concepts {
                name = c["name"];
                if name in self.concept_domains_touched {
                    touched = self.concept_domains_touched[name];
                    if len(touched) >= self.bridge_min_domains {
                        domain_bridges.append({
                            "name": name,
                            "domains_connected": touched,
                            "edge_count": self.concept_edge_counts.get(name, 0)
                        });
                    }
                }
            }

            cluster_label = domain;
            cluster_theme = "";
            cluster_knowledge_level = "surface";
            if concept_count >= 2 {
                try {
                    summary = generate_cluster_summary(
                        concepts=concept_names,
                        descriptions=concept_descriptions
                    );
                    cluster_label = summary.label;
                    cluster_theme = summary.theme;
                    cluster_knowledge_level = summary.knowledge_level;
                } except Exception as e {
                    cluster_label = domain.replace("_", " ").title();
                    cluster_theme = f"A collection of {concept_count} concepts in {domain}";
                    if density == "deep" {
                        cluster_knowledge_level = "deep";
                    } elif density == "moderate" {
                        cluster_knowledge_level = "intermediate";
                    }
                }
            }

            territory = {
                "domain": domain,
                "label": cluster_label,
                "theme": cluster_theme,
                "concept_count": concept_count,
                "concepts": concept_names,
                "density": density,
                "avg_importance": round(avg_importance, 3),
                "depth_distribution": depth_counts,
                "total_access": total_access,
                "cross_connections": cross_connections,
                "connected_domains": connected_domains,
                "is_island": is_island,
                "bridges": domain_bridges,
                "knowledge_level": cluster_knowledge_level
            };
            self.territories.append(territory);

            if is_island {
                self.islands.append(domain);
            }
        }

        density_order = {"dense": 0, "moderate": 1, "sparse": 2};
        self.territories.sort(
            key=lambda (t: dict) { (density_order.get(t["density"], 3), -t["concept_count"]); }
        );

        for concept_name in self.concept_domains_touched {
            touched = self.concept_domains_touched[concept_name];
            if len(touched) >= self.bridge_min_domains {
                self.bridges.append({
                    "name": concept_name,
                    "domains_connected": touched,
                    "edge_count": self.concept_edge_counts.get(concept_name, 0)
                });
        }
        }
        self.bridges.sort(key=lambda (b: dict) { len(b["domains_connected"]); }, reverse=True);

        # Domain-level meta-graph
        domain_adjacency: list = [];
        for pair_key in self.domain_edge_pairs {
            parts = pair_key.split("|");
            domain_adjacency.append({
                "source": parts[0],
                "target": parts[1],
                "weight": self.domain_edge_pairs[pair_key]
            });
        }
        domain_adjacency.sort(key=lambda (d: dict) { d["weight"]; }, reverse=True);

        report {
            "status": "complete",
            "traversal_path": self.traversal_path,
            "territories": self.territories,
            "bridges": self.bridges,
            "islands": self.islands,
            "domain_adjacency": domain_adjacency,
            "stats": {
                "total_nodes": total_nodes,
                "total_concepts": self.total_concepts,
                "total_sources": self.total_sources,
                "total_insights": self.total_insights,
                "total_persons": self.total_persons,
                "total_projects": self.total_projects,
                "total_questions": self.total_questions,
                "total_edges": self.total_edges_seen // 2,
                "num_domains": len(self.domain_concepts),
                "num_bridges": len(self.bridges),
                "num_islands": len(self.islands)
            }
        };
    }
}
