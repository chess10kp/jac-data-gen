# Pathfinder walker — answers questions by walking conceptual paths
# through the graph, scoring them for relevance, and synthesizing answers.

import time;

import from graph.nodes { Concept, Question }
import from graph.edges { relates_to, builds_upon, sourced_from, inspired_by }
import from ai.assess { score_path_relevance, PathRelevanceScore }
import from ai.synthesize { synthesize_answer }
import from ai.narrate { narrate_path, PathNarration }

obj AnchorConcept {
    has name: str;
    has context: str = "";
}

sem identify_anchors = """
Given a user question, identify the 1-3 key concepts the question is about.
These are the anchor points we will search for in a knowledge graph. Return
concise concept names that are likely to match node names in a personal
knowledge graph. For example, the question 'How does Bayesian inference relate
to startup valuation?' should yield anchors like 'Bayesian inference' and
'startup valuation'. Prefer canonical, widely-used concept names over verbose
phrases.
""";

def identify_anchors(question: str) -> list[AnchorConcept] by llm();

def identify_anchors_fallback(question: str) -> list {
    stop = {"how", "does", "is", "are", "what", "why", "the", "like", "to",
            "and", "of", "in", "for", "with", "from", "about", "between",
            "connect", "relate", "connection", "relationship", "do", "a", "an"};
    words = [w.strip("?.,!") for w in question.lower().split() if w.strip("?.,!") not in stop and len(w) > 2];
    anchors: list = [];
    for w in words {
        anchors.append(AnchorConcept(name=w, context=""));
    }
    return anchors;
}

obj FuzzyMatchResult {
    has is_match: bool;
    has confidence: float;
}

sem fuzzy_match_concept = """
Determine whether a knowledge-graph concept node matches the anchor concept the
user is asking about. They do not need to share the exact same name - semantic
equivalence counts. For example, 'GP regression' matches 'Gaussian Processes',
and 'fundraising' matches 'startup fundraising'. Return is_match (true/false)
and confidence (0-1).
""";

def fuzzy_match_concept(
    anchor_name: str,
    anchor_context: str,
    node_name: str,
    node_description: str
) -> FuzzyMatchResult by llm();

walker Pathfinder {
    has question: str;
    has max_depth: int = 7;

    has anchors: list = [];
    has anchor_nodes: dict = {};
    has visited_ids: list = [];
    has traversal_path: list = [];
    has path_descriptions: list = [];
    has path_edges: list = [];
    has candidate_paths: list = [];
    has current_depth: int = 0;

    # Concept-to-concept adjacency built during scan (ignores root edges)
    # so we can reconstruct genuine edge-adjacent paths between anchors.
    has concept_adj: dict = {};       # node_id -> list[node_id] of typed-edge neighbors
    has id_to_name: dict = {};        # node_id -> concept name
    has id_to_desc: dict = {};        # node_id -> concept description

    has best_answer: str = "";
    has narration: str = "";
    has answer_path: list = [];

    # "scan" = locate anchors, "trace" = collect context between them
    has phase: str = "scan";

    can start with Root entry {
        try {
            self.anchors = identify_anchors(self.question);
        } except Exception as e {
            self.anchors = identify_anchors_fallback(self.question);
        }

        for a in self.anchors {
            self.anchor_nodes[a.name] = None;
        }

        self.phase = "scan";
        self.current_depth = 0;
        visit [-->];
    }

    can scan_node with Concept entry {
        if self.phase != "scan" {
            return;
        }

        node_id = str(here.__jac__.id);
        if node_id in self.visited_ids {
            return;
        }
        self.visited_ids.append(node_id);
        self.current_depth += 1;

        self.traversal_path.append(here.name);
        self.path_descriptions.append(here.description);
        self.id_to_name[node_id] = here.name;
        self.id_to_desc[node_id] = here.description;

        here.access_count = here.access_count + 1;
        here.last_accessed = time.time();

        for a in self.anchors {
            if self.anchor_nodes[a.name] is not None {
                continue;
            }

            a_lower = a.name.lower();
            n_lower = here.name.lower();
            if a_lower in n_lower or n_lower in a_lower {
                self.anchor_nodes[a.name] = {
                    "name": here.name,
                    "description": here.description,
                    "node_id": node_id
                };
                continue;
            }

            # Word overlap fallback
            a_words = set(a.name.lower().split());
            n_words = set(here.name.lower().split());
            d_words = set(here.description.lower().split());
            overlap = len(a_words & n_words) + len(a_words & d_words) * 0.5;
            if overlap >= 1.0 {
                self.anchor_nodes[a.name] = {
                    "name": here.name,
                    "description": here.description,
                    "node_id": node_id
                };
            }
        }

        # Build concept-to-concept adjacency BEFORE any early return, so every
        # visited node (including anchors) has its adjacency recorded.
        out_neighbors = [-->][?:Concept];
        in_neighbors = [<--][?:Concept];
        adj_list: list = [];
        for n in out_neighbors {
            adj_list.append(str(n.__jac__.id));
        }
        for n in in_neighbors {
            n_id = str(n.__jac__.id);
            if n_id not in adj_list {
                adj_list.append(n_id);
            }
        }
        self.concept_adj[node_id] = adj_list;

        all_found = True;
        for a in self.anchors {
            if self.anchor_nodes[a.name] is None {
                all_found = False;
                break;
            }
        }
        if all_found {
            return;
        }

        if self.current_depth < self.max_depth * 20 {
            unvisited: list = [];
            for n in out_neighbors {
                if str(n.__jac__.id) not in self.visited_ids {
                    unvisited.append(n);
                }
            }
            if len(unvisited) > 0 {
                visit unvisited;
            }
        }
    }

    # BFS over the concept-only adjacency dict.
    # Returns list of node IDs (empty list if no path exists).
    def _bfs_shortest_path(start_id: str, end_id: str) -> list {
        empty: list = [];
        if start_id == end_id {
            single: list = [start_id];
            return single;
        }
        if start_id not in self.concept_adj {
            return empty;
        }
        visited: set = set();
        visited.add(start_id);
        initial: list = [start_id];
        queue: list = [initial];
        while len(queue) > 0 {
            path = queue.pop(0);
            current = path[-1];
            neighbors_any = self.concept_adj.get(current, empty);
            neighbors: list = list(neighbors_any);
            for nb in neighbors {
                if nb == end_id {
                    result = list(path);
                    result.append(nb);
                    return result;
                }
                if nb not in visited and nb in self.concept_adj {
                    visited.add(nb);
                    if len(path) < 10 {
                        extended = list(path);
                        extended.append(nb);
                        queue.append(extended);
                    }
                }
            }
        }
        return empty;
    }

    can finish with Root exit {
        found = [];
        for a_name in self.anchor_nodes {
            if self.anchor_nodes[a_name] is not None {
                found.append(self.anchor_nodes[a_name]);
            }
        }

        if len(self.traversal_path) > 0 {
            max_path_len = self.max_depth * 2;
            trimmed_concepts = self.traversal_path[:max_path_len];
            trimmed_descs = self.path_descriptions[:max_path_len];

            if len(found) >= 2 {
                # Run BFS on the concept-only adjacency dict to find the actual
                # shortest edge-adjacent path between the two anchor concepts.
                start_id = found[0]["node_id"];
                end_id = found[1]["node_id"];
                path_ids = self._bfs_shortest_path(start_id, end_id);
                if path_ids is not None and len(path_ids) >= 2 and len(path_ids) <= 12 {
                    reconstructed_concepts: list = [];
                    reconstructed_descs: list = [];
                    for nid in path_ids {
                        if nid in self.id_to_name {
                            reconstructed_concepts.append(self.id_to_name[nid]);
                            reconstructed_descs.append(
                                self.id_to_desc[nid] if nid in self.id_to_desc else ""
                            );
                        }
                    }
                    if len(reconstructed_concepts) >= 2 {
                        trimmed_concepts = reconstructed_concepts;
                        trimmed_descs = reconstructed_descs;
                    }
                }
            }

            try {
                relevance_score = score_path_relevance(
                    self.question, trimmed_concepts, trimmed_descs
                );

                node_contexts: list = [];
                for i in range(len(trimmed_concepts)) {
                    node_contexts.append({
                        "name": trimmed_concepts[i],
                        "description": trimmed_descs[i] if i < len(trimmed_descs) else ""
                    });
                }

                paths_data = [{
                    "concepts": trimmed_concepts,
                    "descriptions": trimmed_descs,
                    "relevance": relevance_score.relevance,
                    "key_connections": relevance_score.key_connections
                }];

                self.best_answer = synthesize_answer(
                    self.question, paths_data, node_contexts
                );

                edge_labels = ["relates_to" for _ in trimmed_concepts];
                path_narration = narrate_path(
                    trimmed_concepts, edge_labels, self.question
                );
                self.narration = path_narration.narration;
            } except Exception as e {
                self.best_answer = (
                    "Path found: " + " -> ".join(trimmed_concepts) + ". "
                    + "This traversal connects " + trimmed_concepts[0]
                    + " to " + trimmed_concepts[-1]
                    + " through " + str(len(trimmed_concepts) - 2)
                    + " intermediate concepts."
                );
                self.narration = "";
            }

            self.answer_path = trimmed_concepts;
        }

        q_node = Question(
            text=self.question,
            asked_at=time.time(),
            answered=len(self.best_answer) > 0,
            answer_path=self.answer_path,
            answer_text=self.best_answer
        );
        here ++> q_node;

        report {
            "question": self.question,
            "answer": self.best_answer,
            "narration": self.narration,
            "traversal_path": self.traversal_path,
            "answer_path": self.answer_path,
            "path_descriptions": self.path_descriptions,
            "anchors_requested": [a.name for a in self.anchors],
            "anchors_found": [
                self.anchor_nodes[a_name]
                for a_name in self.anchor_nodes
                if self.anchor_nodes[a_name] is not None
            ],
            "walker_type": "pathfinder",
            "walker_color": "#00D4FF"
        };
    }
}
