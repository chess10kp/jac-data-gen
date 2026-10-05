# ORBIT - main app entry point and public API walkers

import json;
import time;
import os;

import from engine.setup_llm { ensure_groq_key as _setup_llm }

import from graph.nodes { Concept, Source, Insight, Question, Person, Project }
import from graph.edges { relates_to, builds_upon, contradicts, sourced_from, inspired_by, applied_in, mentioned_by, temporal }

import from ai.extract { extract_concepts, extract_people, extract_relationships }
import from ai.assess { assess_relationship, detect_contradiction, score_path_relevance }
import from ai.synthesize { generate_insight, synthesize_answer, generate_cluster_summary }
import from ai.narrate { narrate_path, describe_contradiction, generate_digest }

import from walkers.pathfinder { identify_anchors, identify_anchors_fallback }

import from graph.seed { SeedGraph }
import from walkers.ingestor { Ingestor }
import from walkers.explorer { Explorer }
import from walkers.pathfinder { Pathfinder }
import from walkers.consolidator { Consolidator }
import from walkers.cartographer { Cartographer }


walker:pub seed_graph {
    has data_path: str = "data/demo_knowledge.json";
    has node_map: dict = {};
    has node_count: int = 0;
    has edge_count: int = 0;

    can seed with Root entry {
        now = time.time();

        json_path = self.data_path;
        if not os.path.isabs(json_path) {
            for base in [os.getcwd(), os.path.dirname(os.path.abspath(__file__))] {
                candidate = os.path.join(base, json_path);
                if os.path.exists(candidate) {
                    json_path = candidate;
                    break;
                }
            }
            if not os.path.exists(json_path) {
                file_dir = os.path.dirname(os.path.abspath(__file__));
                project_root = os.path.dirname(os.path.dirname(file_dir));
                candidate = os.path.join(project_root, self.data_path);
                if os.path.exists(candidate) {
                    json_path = candidate;
                }
            }
        }

        with open(json_path, "r") as f {
            data = json.load(f);
        }

        for node_data in data.get("nodes", []) {
            new_node = self._create_node(node_data, now);
            if new_node is not None {
                here ++> (new_node as Concept);
                self.node_map[node_data["id"]] = new_node;
                self.node_count += 1;
            }
        }

        for edge_data in data.get("edges", []) {
            src = self.node_map.get(edge_data.get("source", ""));
            tgt = self.node_map.get(edge_data.get("target", ""));
            if src is not None and tgt is not None {
                self._create_edge(src, tgt, edge_data, now);
                self.edge_count += 1;
            }
        }

        report {
            "status": "seeded",
            "node_count": self.node_count,
            "edge_count": self.edge_count
        };
    }

    def _create_node(data: dict, now: float) -> any {
        t = data.get("type", "");
        if t == "Concept" {
            return Concept(
                name=data.get("name", ""), description=data.get("description", ""),
                domain=data.get("domain", "general"), importance=data.get("importance", 0.5),
                created_at=now, last_accessed=now, access_count=0, depth=data.get("depth", "surface")
            );
        } elif t == "Source" {
            return Source(
                title=data.get("title", ""), source_type=data.get("source_type", "article"),
                content=data.get("content", ""), url=data.get("url", ""),
                ingested_at=now, summary=data.get("summary", "")
            );
        } elif t == "Insight" {
            return Insight(
                title=data.get("title", ""), description=data.get("description", ""),
                confidence=data.get("confidence", 0.5), path=data.get("path", []),
                generated_at=now, validated=data.get("validated", False)
            );
        } elif t == "Question" {
            return Question(
                text=data.get("text", ""), asked_at=now,
                answered=data.get("answered", False), answer_path=data.get("answer_path", []),
                answer_text=data.get("answer_text", "")
            );
        } elif t == "Person" {
            return Person(name=data.get("name", ""), context=data.get("context", ""));
        } elif t == "Project" {
            return Project(
                name=data.get("name", ""), description=data.get("description", ""),
                status=data.get("status", "active")
            );
        } else {
            return None;
        }
    }

    def _create_edge(src: any, tgt: any, data: dict, now: float) {
        t = data.get("type", "relates_to");
        if t == "relates_to" {
            src +>:relates_to(
                strength=data.get("strength", 0.5), relationship=data.get("relationship", ""),
                created_at=now, last_reinforced=now, reinforcement_count=1
            ):+> tgt;
        } elif t == "builds_upon" {
            src +>:builds_upon(
                strength=data.get("strength", 0.7), explanation=data.get("explanation", ""),
                created_at=now
            ):+> tgt;
        } elif t == "contradicts" {
            src +>:contradicts(
                strength=data.get("strength", 0.5), tension=data.get("tension", ""),
                resolved=data.get("resolved", False), created_at=now
            ):+> tgt;
        } elif t == "sourced_from" {
            src +>:sourced_from(
                relevance=data.get("relevance", 0.8), excerpt=data.get("excerpt", "")
            ):+> tgt;
        } elif t == "inspired_by" {
            src +>:inspired_by(created_at=now, context=data.get("context", "")):+> tgt;
        } elif t == "applied_in" {
            src +>:applied_in(how=data.get("how", "")):+> tgt;
        } elif t == "mentioned_by" {
            src +>:mentioned_by(context=data.get("context", "")):+> tgt;
        } elif t == "temporal" {
            src +>:temporal(timestamp=data.get("timestamp", now), sequence_type=data.get("sequence_type", "")):+> tgt;
        } else {
            src +>:relates_to(
                strength=data.get("strength", 0.5), relationship=data.get("relationship", ""),
                created_at=now, last_reinforced=now, reinforcement_count=1
            ):+> tgt;
        }
    }
}

walker:pub ingest_knowledge {
    has text: str;
    has source_type: str = "note";
    has url: str = "";
    has traversal_path: list = [];
    has new_concepts: list = [];
    has new_edges: list = [];

    can ingest with Root entry {
        now = time.time();

        title_text = self.text[:80] + ("..." if len(self.text) > 80 else "");
        source_node = Source(
            title=title_text, source_type=self.source_type,
            content=self.text, url=self.url, ingested_at=now, summary=""
        );
        here ++> source_node;

        extracted = extract_concepts(self.text, self.source_type);
        for c in extracted {
            new_concept = Concept(
                name=c.name, description=c.description, domain=c.domain,
                importance=0.5, created_at=now, last_accessed=now,
                access_count=1, depth=c.depth
            );
            here ++> new_concept;
            new_concept +>:sourced_from(relevance=0.9, excerpt=""):+> source_node;
            self.new_concepts.append(new_concept);
        }

        visit [-->][?:Concept];
    }

    can assess with Concept entry {
        is_new = False;
        for nc in self.new_concepts {
            if nc is here { is_new = True; break; }
        }
        if is_new { return; }

        self.traversal_path.append(here.name);
        here.access_count += 1;
        here.last_accessed = time.time();

        for new_c in self.new_concepts {
            assessment = assess_relationship(new_c.name, new_c.description, here.name, here.description);
            if assessment.related and assessment.strength > 0.3 {
                now = time.time();
                new_c +>:relates_to(
                    strength=assessment.strength, relationship=assessment.explanation,
                    created_at=now, last_reinforced=now, reinforcement_count=1
                ):+> here;
                self.new_edges.append({
                    "source": new_c.name, "target": here.name,
                    "type": assessment.relationship_type, "strength": assessment.strength
                });
            }
        }
    }

    can finish with Root exit {
        report {
            "source_title": self.text[:80],
            "new_concepts": [c.name for c in self.new_concepts],
            "new_concepts_count": len(self.new_concepts),
            "new_edges_count": len(self.new_edges),
            "traversal_path": self.traversal_path,
            "new_edges": self.new_edges
        };
    }
}

walker:pub ask_question {
    has question: str;
    has traversal_path: list = [];
    has path_descriptions: list = [];
    has best_answer: str = "";
    has answer_path: list = [];
    has anchors: list = [];
    has anchor_nodes: dict = {};
    has visited_ids: list = [];

    can start with Root entry {
        try {
            self.anchors = identify_anchors(self.question);
        } except Exception {
            self.anchors = identify_anchors_fallback(self.question);
        }
        self.anchor_nodes = {};
        for a in self.anchors {
            self.anchor_nodes[a.name] = None;
        }
        self.visited_ids = [];
        visit [-->];
    }

    can scan with Concept entry {
        node_id = str(here);
        if node_id in self.visited_ids { return; }
        self.visited_ids.append(node_id);
        self.traversal_path.append(here.name);
        self.path_descriptions.append(here.description);
        here.access_count += 1;
        here.last_accessed = time.time();

        for a in self.anchors {
            if self.anchor_nodes.get(a.name) is not None { continue; }
            a_lower = a.name.lower();
            n_lower = here.name.lower();
            if a_lower in n_lower or n_lower in a_lower {
                self.anchor_nodes[a.name] = {"name": here.name, "description": here.description};
            }
        }

        all_found = True;
        for a in self.anchors {
            if self.anchor_nodes.get(a.name) is None { all_found = False; break; }
        }
        if all_found { return; }

        if len(self.visited_ids) < 150 {
            neighbors = [-->][?:Concept];
            unvisited = [n for n in neighbors if str(n) not in self.visited_ids];
            if len(unvisited) > 0 { visit unvisited; }
        }
    }

    can finish with Root exit {
        found = [v for v in self.anchor_nodes.values() if v is not None];
        if len(self.traversal_path) > 0 {
            max_len = 14;
            concepts = self.traversal_path[:max_len];
            descs = self.path_descriptions[:max_len];

            try {
                relevance = score_path_relevance(self.question, concepts, descs);
                node_ctx = [{"name": concepts[i], "description": descs[i] if i < len(descs) else ""} for i in range(len(concepts))];
                paths_data = [{"concepts": concepts, "descriptions": descs, "relevance": relevance.relevance, "key_connections": relevance.key_connections}];
                self.best_answer = synthesize_answer(self.question, paths_data, node_ctx);
            } except Exception {
                self.best_answer = "Path: " + " -> ".join(concepts) + ". Connects " + concepts[0] + " to " + concepts[-1] + " through " + str(len(concepts) - 2) + " intermediate concepts.";
            }
            self.answer_path = concepts;
        }

        report {
            "question": self.question,
            "answer": self.best_answer,
            "traversal_path": self.traversal_path,
            "answer_path": self.answer_path,
            "anchors_found": [v for v in self.anchor_nodes.values() if v is not None],
            "walker_type": "pathfinder",
            "walker_color": "#00D4FF"
        };
    }
}

walker:pub explore {
    has max_hops: int = 6;
    has min_confidence: float = 0.5;
    has traversal_path: list = [];
    has path_descriptions: list = [];
    has discoveries: list = [];
    has hops_taken: int = 0;
    has visited_ids: list = [];

    can begin with Root entry {
        concepts = [-->][?:Concept];
        if len(concepts) == 0 {
            report {"status": "empty_graph", "traversal_path": [], "discoveries": []};
            disengage;
        }
        import random;
        import math;
        now = time.time();
        weights = [c.importance + 0.3 * math.exp(-(now - c.created_at) / 86400.0) for c in concepts];
        starter = random.choices(concepts, weights=[max(w, 0.01) for w in weights], k=1)[0];
        visit starter;
    }

    can explore_node with Concept entry {
        self.traversal_path.append(here.name);
        self.path_descriptions.append(here.description);
        self.visited_ids.append(here.__jac__.id);
        here.access_count += 1;
        here.last_accessed = time.time();
        self.hops_taken += 1;

        for e in ([edge <-->] as list) {
            if hasattr(e, "last_reinforced") {
                e.last_reinforced = time.time();
                e.reinforcement_count = e.reinforcement_count + 1;
                e.strength = min(e.strength + 0.02, 1.0);
            }
        }

        if self.hops_taken >= self.max_hops {
            if len(self.traversal_path) >= 3 and self.traversal_path[0] != self.traversal_path[-1] {
                insight_result = generate_insight(
                    self.traversal_path[0], here.name,
                    self.traversal_path, self.path_descriptions
                );
                if insight_result.confidence >= self.min_confidence {
                    new_insight = Insight(
                        title=insight_result.title, description=insight_result.description,
                        confidence=insight_result.confidence, path=self.traversal_path,
                        generated_at=time.time()
                    );
                    root ++> new_insight;
                    self.discoveries.append({
                        "title": insight_result.title,
                        "description": insight_result.description,
                        "confidence": insight_result.confidence,
                        "path": self.traversal_path
                    });
                }
            }
            report {"status": "complete", "traversal_path": self.traversal_path, "discoveries": self.discoveries, "hops_taken": self.hops_taken};
            disengage;
        }

        import random;
        neighbors = [-->][?:Concept];
        unvisited = [n for n in neighbors if n.__jac__.id not in self.visited_ids];
        candidates = unvisited if len(unvisited) > 0 else neighbors;
        if len(candidates) == 0 {
            report {"status": "dead_end", "traversal_path": self.traversal_path, "discoveries": self.discoveries, "hops_taken": self.hops_taken};
            disengage;
        }
        weights = [1.0 / (0.05 + 0.5) for _ in candidates];
        chosen = random.choices(candidates, weights=weights, k=1)[0];
        visit chosen;
    }
}

walker:pub consolidate {
    has decay_threshold: float = 0.2;
    has traversal_path: list = [];
    has weak_edges_found: list = [];
    has orphans_found: list = [];
    has visited_ids: list = [];

    can begin with Root entry {
        visit [-->][?:Concept];
    }

    can analyze with Concept entry {
        node_id = here.__jac__.id;
        if node_id in self.visited_ids { return; }
        self.visited_ids.append(node_id);
        self.traversal_path.append(here.name);
        here.access_count += 1;
        here.last_accessed = time.time();

        for e in ([edge <-->] as list) {
            if hasattr(e, "strength") and e.strength < self.decay_threshold {
                self.weak_edges_found.append({
                    "from": here.name, "edge_type": type(e).__name__,
                    "strength": round(e.strength, 3),
                    "message": f"Connection from '{here.name}' is fading (strength: {round(e.strength, 3)})"
                });
            }
        }

        neighbors = [-->][?:Concept];
        incoming = [<--][?:Concept];
        if len(neighbors) + len(incoming) < 2 {
            self.orphans_found.append({
                "name": here.name, "domain": here.domain,
                "message": f"'{here.name}' is isolated"
            });
        }

        unvisited = [n for n in neighbors if n.__jac__.id not in self.visited_ids];
        if len(unvisited) > 0 { visit unvisited; }
    }

    can finish with Root exit {
        report {
            "status": "complete",
            "traversal_path": self.traversal_path,
            "concepts_analyzed": len(self.traversal_path),
            "weak_edges": self.weak_edges_found,
            "weak_edge_count": len(self.weak_edges_found),
            "orphans": self.orphans_found,
            "orphan_count": len(self.orphans_found)
        };
    }
}

walker:pub map_territory {
    has traversal_path: list = [];
    has visited_ids: list = [];
    has domain_concepts: dict = {};
    has total_concepts: int = 0;
    has domain_edge_pairs: dict = {};

    can begin with Root entry {
        visit [-->];
    }

    can map_concept with Concept entry {
        node_id = here.__jac__.id;
        if node_id in self.visited_ids { return; }
        self.visited_ids.append(node_id);
        self.traversal_path.append({"type": "concept", "name": here.name, "domain": here.domain});
        here.access_count += 1;
        here.last_accessed = time.time();
        self.total_concepts += 1;

        domain = here.domain;
        if domain not in self.domain_concepts { self.domain_concepts[domain] = []; }
        self.domain_concepts[domain].append({
            "name": here.name, "description": here.description,
            "importance": here.importance, "depth": here.depth
        });

        neighbors = [-->][?:Concept];
        for n in neighbors {
            if n.domain != domain {
                pair_key = "|".join(sorted([domain, n.domain]));
                if pair_key not in self.domain_edge_pairs { self.domain_edge_pairs[pair_key] = 0; }
                self.domain_edge_pairs[pair_key] += 1;
            }
        }
        visit [-->];
    }

    can finish with Root exit {
        territories = [];
        for domain in self.domain_concepts {
            concepts = self.domain_concepts[domain];
            count = len(concepts);
            density = "dense" if count >= 10 else ("moderate" if count >= 5 else "sparse");
            avg_imp = sum(c["importance"] for c in concepts) / count if count > 0 else 0;

            cross = 0;
            connected_domains = [];
            for pk in self.domain_edge_pairs {
                if domain in pk.split("|") {
                    cross += self.domain_edge_pairs[pk];
                    parts = pk.split("|");
                    other = parts[1] if parts[0] == domain else parts[0];
                    if other not in connected_domains { connected_domains.append(other); }
                }
            }

            territories.append({
                "domain": domain, "concept_count": count, "density": density,
                "avg_importance": round(avg_imp, 3), "is_island": cross == 0,
                "concepts": [c["name"] for c in concepts],
                "connected_domains": connected_domains
            });
        }
        territories.sort(key=lambda (t: dict) { -t["concept_count"]; });

        report {
            "status": "complete",
            "traversal_path": self.traversal_path,
            "territories": territories,
            "stats": {
                "total_concepts": self.total_concepts,
                "num_domains": len(self.domain_concepts)
            }
        };
    }
}

walker get_graph {
    has nodes_data: list = [];
    has edges_data: list = [];

    can start with Root entry {
        visit [-->];
    }

    can collect_concept with Concept entry {
        self.nodes_data.append({
            "id": str(here.__jac__.id),
            "type": "Concept",
            "name": here.name,
            "description": here.description,
            "domain": here.domain,
            "importance": here.importance,
            "depth": here.depth,
            "access_count": here.access_count
        });
        for neighbor in [-->] {
            edges = [edge here --> neighbor];
            for e in edges {
                self.edges_data.append({
                    "source": str(here.__jac__.id),
                    "target": str(neighbor.__jac__.id),
                    "type": type(e).__name__,
                    "strength": getattr(e, 'strength', 0.5),
                    "relationship": getattr(e, 'relationship', getattr(e, 'explanation', getattr(e, 'tension', '')))
                });
            }
        }
    }

    can collect_source with Source entry {
        self.nodes_data.append({
            "id": str(here.__jac__.id),
            "type": "Source",
            "name": here.title,
            "title": here.title,
            "source_type": here.source_type,
            "content": here.content,
            "summary": here.summary
        });
        # Collect outgoing edges (Sources have sourced_from -> Concept edges)
        for neighbor in [-->] {
            edges = [edge here --> neighbor];
            for e in edges {
                self.edges_data.append({
                    "source": str(here.__jac__.id),
                    "target": str(neighbor.__jac__.id),
                    "type": type(e).__name__,
                    "strength": getattr(e, 'strength', 0.5),
                    "relationship": getattr(e, 'relationship', getattr(e, 'explanation', getattr(e, 'tension', '')))
                });
            }
        }
    }

    can collect_insight with Insight entry {
        self.nodes_data.append({
            "id": str(here.__jac__.id),
            "type": "Insight",
            "name": here.title,
            "title": here.title,
            "description": here.description,
            "confidence": here.confidence,
            "path": here.path
        });
        for neighbor in [-->] {
            edges = [edge here --> neighbor];
            for e in edges {
                self.edges_data.append({
                    "source": str(here.__jac__.id),
                    "target": str(neighbor.__jac__.id),
                    "type": type(e).__name__,
                    "strength": getattr(e, 'strength', 0.5),
                    "relationship": getattr(e, 'relationship', getattr(e, 'explanation', getattr(e, 'tension', '')))
                });
            }
        }
    }

    can collect_person with Person entry {
        self.nodes_data.append({
            "id": str(here.__jac__.id),
            "type": "Person",
            "name": here.name,
            "context": here.context
        });
        for neighbor in [-->] {
            edges = [edge here --> neighbor];
            for e in edges {
                self.edges_data.append({
                    "source": str(here.__jac__.id),
                    "target": str(neighbor.__jac__.id),
                    "type": type(e).__name__,
                    "strength": getattr(e, 'strength', 0.5),
                    "relationship": getattr(e, 'relationship', getattr(e, 'explanation', getattr(e, 'tension', '')))
                });
            }
        }
    }

    can collect_project with Project entry {
        self.nodes_data.append({
            "id": str(here.__jac__.id),
            "type": "Project",
            "name": here.name,
            "description": here.description,
            "status": here.status
        });
        for neighbor in [-->] {
            edges = [edge here --> neighbor];
            for e in edges {
                self.edges_data.append({
                    "source": str(here.__jac__.id),
                    "target": str(neighbor.__jac__.id),
                    "type": type(e).__name__,
                    "strength": getattr(e, 'strength', 0.5),
                    "relationship": getattr(e, 'relationship', getattr(e, 'explanation', getattr(e, 'tension', '')))
                });
            }
        }
    }

    can collect_question with Question entry {
        self.nodes_data.append({
            "id": str(here.__jac__.id),
            "type": "Question",
            "name": here.text,
            "text": here.text,
            "answered": here.answered,
            "answer_text": here.answer_text
        });
    }

    can finish with Root exit {
        report {
            "nodes": self.nodes_data,
            "edges": self.edges_data,
            "stats": {
                "total_nodes": len(self.nodes_data),
                "total_edges": len(self.edges_data),
                "concepts": len([n for n in self.nodes_data if n["type"] == "Concept"]),
                "sources": len([n for n in self.nodes_data if n["type"] == "Source"]),
                "insights": len([n for n in self.nodes_data if n["type"] == "Insight"]),
                "questions": len([n for n in self.nodes_data if n["type"] == "Question"])
            }
        };
    }
}


with entry {
    print("+===========================================+");
    print("|          ORBIT - Second Brain             |");
    print("|     Your Knowledge Graph That Thinks      |");
    print("+===========================================+");
    print("");
    print("Seeding demo knowledge graph...");

    seeder = root spawn seed_graph();
    if seeder.reports {
        stats = seeder.reports[0];
        print(f"Loaded: {stats.get('node_count', '?')} nodes, {stats.get('edge_count', '?')} edges");
    }

    print("");
    print("ORBIT is ready.");
    print("  Run with API:  jac serve src/app.jac");
    print("  Run directly:  jac run src/app.jac");
    print("");
}
