# Loads demo knowledge base from JSON into the Jac graph

import json;
import time;
import os;

import from graph.nodes { Concept, Source, Insight, Question, Person, Project }
import from graph.edges { relates_to, builds_upon, contradicts, sourced_from, inspired_by, applied_in, mentioned_by, temporal }

walker SeedGraph {
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
            node_id = node_data["id"];
            new_node = self.create_node(node_data, now);
            if new_node is not None {
                here ++> (new_node as Concept);
                self.node_map[node_id] = new_node;
                self.node_count += 1;
            }
        }

        for edge_data in data.get("edges", []) {
            source_id = edge_data.get("source", "");
            target_id = edge_data.get("target", "");
            source_node = self.node_map.get(source_id);
            target_node = self.node_map.get(target_id);

            if source_node is None or target_node is None {
                continue;
            }

            self.create_edge(source_node, target_node, edge_data, now);
            self.edge_count += 1;
        }

        print(
            f"[ORBIT Seed] Graph seeded: {self.node_count} nodes, "
            f"{self.edge_count} edges created."
        );
    }

    def create_node(data: dict, now: float) -> any {
        node_type = data.get("type", "");

        if node_type == "Concept" {
            return Concept(
                name=data.get("name", ""),
                description=data.get("description", ""),
                domain=data.get("domain", "general"),
                importance=data.get("importance", 0.5),
                created_at=now,
                last_accessed=now,
                access_count=0,
                depth=data.get("depth", "surface")
            );
        } elif node_type == "Source" {
            return Source(
                title=data.get("title") or data.get("name", ""),
                source_type=data.get("source_type", "article"),
                content=data.get("content") or data.get("description", ""),
                url=data.get("url", ""),
                ingested_at=now,
                summary=data.get("summary", "")
            );
        } elif node_type == "Insight" {
            return Insight(
                title=data.get("title") or data.get("name", ""),
                description=data.get("description", ""),
                confidence=data.get("confidence", 0.5),
                path=data.get("path", []),
                generated_at=now,
                validated=data.get("validated", False)
            );
        } elif node_type == "Question" {
            return Question(
                text=data.get("text", ""),
                asked_at=now,
                answered=data.get("answered", False),
                answer_path=data.get("answer_path", []),
                answer_text=data.get("answer_text", "")
            );
        } elif node_type == "Person" {
            return Person(
                name=data.get("name", ""),
                context=data.get("context", "")
            );
        } elif node_type == "Project" {
            return Project(
                name=data.get("name", ""),
                description=data.get("description", ""),
                status=data.get("status", "active")
            );
        } else {
            print(f"[ORBIT Seed] Warning: Unknown node type '{node_type}', skipping.");
            return None;
        }
    }

    def create_edge(src: any, tgt: any, data: dict, now: float) {
        edge_type = data.get("type", "relates_to");

        if edge_type == "relates_to" {
            src +>:relates_to(
                strength=data.get("strength", 0.5),
                relationship=data.get("relationship", ""),
                created_at=now,
                last_reinforced=now,
                reinforcement_count=1
            ):+> tgt;
        } elif edge_type == "builds_upon" {
            src +>:builds_upon(
                strength=data.get("strength", 0.7),
                explanation=data.get("explanation", ""),
                created_at=now
            ):+> tgt;
        } elif edge_type == "contradicts" {
            src +>:contradicts(
                strength=data.get("strength", 0.5),
                tension=data.get("tension", ""),
                resolved=data.get("resolved", False),
                created_at=now
            ):+> tgt;
        } elif edge_type == "sourced_from" {
            src +>:sourced_from(
                relevance=data.get("relevance", 0.8),
                excerpt=data.get("excerpt", "")
            ):+> tgt;
        } elif edge_type == "inspired_by" {
            src +>:inspired_by(
                created_at=now,
                context=data.get("context", "")
            ):+> tgt;
        } elif edge_type == "applied_in" {
            src +>:applied_in(
                how=data.get("how", "")
            ):+> tgt;
        } elif edge_type == "mentioned_by" {
            src +>:mentioned_by(
                context=data.get("context", "")
            ):+> tgt;
        } elif edge_type == "temporal" {
            src +>:temporal(
                timestamp=data.get("timestamp", now),
                sequence_type=data.get("sequence_type", "")
            ):+> tgt;
        } else {
            print(f"[ORBIT Seed] Warning: Unknown edge type '{edge_type}', using relates_to.");
            src +>:relates_to(
                strength=data.get("strength", 0.5),
                relationship=data.get("relationship", f"unknown type: {edge_type}"),
                created_at=now,
                last_reinforced=now,
                reinforcement_count=1
            ):+> tgt;
        }
    }
}

def seed_knowledge_graph(root_node: Root, data_path: str = "data/demo_knowledge.json") -> dict {
    seeder = root_node spawn SeedGraph(data_path=data_path);
    return seeder.node_map;
}
