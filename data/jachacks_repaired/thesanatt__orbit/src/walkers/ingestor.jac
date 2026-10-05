# Ingestor walker — ingests raw text, extracts concepts, and walks the
# existing graph to find connections (graph traversal, not RAG).

import time;

import from graph.nodes { Concept, Source, Person }
import from graph.edges { relates_to, builds_upon, contradicts, sourced_from, inspired_by, mentioned_by, temporal }
import from ai.extract { extract_concepts, extract_people, extract_relationships }
import from ai.assess { assess_relationship }


walker Ingestor {
    has text: str;
    has source_type: str = "note";
    has url: str = "";

    has traversal_path: list = [];
    has new_concepts: list = [];
    has new_people: list = [];
    has new_edges: list = [];
    has source_node: Source | None = None;
    has concept_names: list = [];
    has concept_descriptions: list = [];
    has max_existing_visits: int = 50;
    has existing_visited: int = 0;
    has visited_ids: list = [];

    can ingest with Root entry {
        now = time.time();

        # IMPORTANT: collect existing Persons/Concepts BEFORE we create anything new.
        # Jac's here++> operator appears to reset the `[-->]` cursor during the
        # walker ability, so we must snapshot the graph state first.
        existing_people_by_name: dict = {};
        existing_concepts_by_name: dict = {};
        for p_node in [-->][?:Person] {
            p_key = p_node.name.lower().strip();
            existing_people_by_name[p_key] = p_node;
        }
        for c_node in [-->][?:Concept] {
            c_key = c_node.name.lower().strip();
            existing_concepts_by_name[c_key] = c_node;
        }

        title_text = self.text[:80];
        if len(self.text) > 80 {
            title_text = title_text + "...";
        }

        self.source_node = Source(
            title=title_text,
            source_type=self.source_type,
            content=self.text,
            url=self.url,
            ingested_at=now,
            summary=""
        );
        here ++> (self.source_node as Source);

        # Extract people FIRST so we can skip any Concepts that are really persons.
        person_names_lower: set = set();
        try {
            extracted_people = extract_people(self.text);
            for person_data in extracted_people {
                key = person_data.name.lower().strip();
                person_names_lower.add(key);
                if key in existing_people_by_name {
                    # Reuse existing Person node, link it to the new Source
                    existing_person = existing_people_by_name[key];
                    existing_person +>:mentioned_by(
                        context=person_data.context
                    ):+> (self.source_node as Source);
                    continue;
                }
                new_person = Person(
                    name=person_data.name,
                    context=person_data.context
                );
                here ++> new_person;
                self.new_people.append(new_person);
            }
        } except Exception as e {
            self.new_people = [];
        }

        try {
            extracted_concepts = extract_concepts(self.text, self.source_type);
        } except Exception as e {
            extracted_concepts = [];
        }

        for concept_data in extracted_concepts {
            # Skip if this "concept" is actually a person name we just added
            key = concept_data.name.lower().strip();
            if key in person_names_lower {
                continue;
            }
            # Skip if a Concept with this name already exists; just link Source to it
            if key in existing_concepts_by_name {
                existing_c = existing_concepts_by_name[key];
                existing_c +>:sourced_from(relevance=0.85, excerpt=""):+> (self.source_node as Source);
                existing_c.access_count = existing_c.access_count + 1;
                continue;
            }
            new_concept = Concept(
                name=concept_data.name,
                description=concept_data.description,
                domain=concept_data.domain,
                importance=0.5,
                created_at=now,
                last_accessed=now,
                access_count=1,
                depth=concept_data.depth
            );
            here ++> new_concept;

            new_concept +>:sourced_from(
                relevance=0.9,
                excerpt=""
            ):+> (self.source_node as Source);

            self.new_concepts.append(new_concept);
            self.concept_names.append(concept_data.name);
            self.concept_descriptions.append(concept_data.description);
        }

        # Link each Person to the Source they came from
        for person_node in self.new_people {
            person_node +>:mentioned_by(
                context=person_node.context
            ):+> (self.source_node as Source);
        }

        # Wire relationships between newly extracted concepts
        # (LLM tool-calling fails on short/simple inputs like "X is smart" —
        # wrap to keep the walker alive with partial progress)
        if len(self.concept_names) > 1 {
            try {
                intra_rels = extract_relationships(
                    self.concept_names,
                    self.concept_descriptions
                );
                for rel in intra_rels {
                    src_node: Concept | None = None;
                    tgt_node: Concept | None = None;
                    for c in self.new_concepts {
                        if c.name == rel.source_concept {
                            src_node = c;
                        }
                        if c.name == rel.target_concept {
                            tgt_node = c;
                        }
                    }
                    if src_node is not None and tgt_node is not None and src_node is not tgt_node {
                        self.create_typed_edge(
                            src_node, tgt_node,
                            rel.relationship_type,
                            rel.strength,
                            rel.explanation,
                            now
                        );
                    }
                }
            } except Exception as e {
                _ = 0;
            }
        }

        for person_node in self.new_people {
            for concept_node in self.new_concepts {
                person_node +>:mentioned_by(
                    context=person_node.context
                ):+> concept_node;
            }
        }

        # Temporal edges capture co-occurrence in the same ingestion
        if len(self.new_concepts) > 1 {
            for i in range(len(self.new_concepts) - 1) {
                self.new_concepts[i] +>:temporal(
                    timestamp=now,
                    sequence_type="same_ingestion"
                ):+> self.new_concepts[i + 1];
            }
        }

        # Now walk existing concepts to find cross-connections.
        # CANNOT use `visit [-->][?:Concept]` here — Jac's `here ++>` operator
        # earlier in this ability invalidated the `[-->]` enumeration, so it
        # would only see the newly created nodes. Instead, visit the existing
        # concept nodes we snapshotted before the mutation.
        existing_concept_nodes: list = [];
        for ec in existing_concepts_by_name.values() {
            existing_concept_nodes.append(ec);
        }
        if len(existing_concept_nodes) > 0 {
            visit existing_concept_nodes;
        }
    }

    can assess_connections with Concept entry {
        node_id = here.__jac__.id;
        if node_id in self.visited_ids { return; }
        self.visited_ids.append(node_id);

        # Skip nodes we just created
        is_new = False;
        for nc in self.new_concepts {
            if nc is here {
                is_new = True;
                break;
            }
        }
        if is_new {
            if self.existing_visited < self.max_existing_visits {
                neighbors = [-->][?:Concept];
                unvisited = [n for n in neighbors if n.__jac__.id not in self.visited_ids];
                if len(unvisited) > 0 { visit unvisited; }
            }
            return;
        }

        self.traversal_path.append(here.name);
        self.existing_visited += 1;

        here.access_count = here.access_count + 1;
        here.last_accessed = time.time();

        for new_concept in self.new_concepts {
            try {
                assessment = assess_relationship(
                    new_concept.name,
                    new_concept.description,
                    here.name,
                    here.description
                );
                if assessment.related and assessment.strength > 0.3 {
                    now = time.time();
                    self.create_typed_edge(
                        new_concept, here,
                        assessment.relationship_type,
                        assessment.strength,
                        assessment.explanation,
                        now
                    );
                }
            } except Exception as e {
                _ = 0;
            }
        }

        if self.existing_visited < self.max_existing_visits {
            neighbors = [-->][?:Concept];
            unvisited = [n for n in neighbors if n.__jac__.id not in self.visited_ids];
            if len(unvisited) > 0 { visit unvisited; }
        }
    }

    can finish with Root exit {
        concept_names: list = [];
        for c in self.new_concepts {
            concept_names.append(c.name);
        }
        people_names: list = [];
        for p in self.new_people {
            people_names.append(p.name);
        }

        report {
            "source_title": self.source_node.title if self.source_node is not None else "",
            "source_type": self.source_type,
            "new_concepts": concept_names,
            "new_people": people_names,
            "new_concepts_count": len(self.new_concepts),
            "new_people_count": len(self.new_people),
            "new_edges_count": len(self.new_edges),
            "existing_concepts_visited": self.existing_visited,
            "traversal_path": self.traversal_path,
            "new_edges": self.new_edges
        };
    }

    def create_typed_edge(
        src: Concept,
        tgt: Concept,
        rel_type: str,
        strength: float,
        explanation: str,
        now: float
    ) {
        if rel_type == "builds_upon" {
            src +>:builds_upon(
                strength=strength,
                explanation=explanation,
                created_at=now
            ):+> tgt;
        } elif rel_type == "contradicts" {
            src +>:contradicts(
                strength=strength,
                tension=explanation,
                resolved=False,
                created_at=now
            ):+> tgt;
        } elif rel_type == "inspired_by" {
            src +>:inspired_by(
                created_at=now,
                context=explanation
            ):+> tgt;
        } else {
            src +>:relates_to(
                strength=strength,
                relationship=explanation,
                created_at=now,
                last_reinforced=now,
                reinforcement_count=1
            ):+> tgt;
        }

        self.new_edges.append({
            "source": src.name,
            "target": tgt.name,
            "type": rel_type,
            "strength": strength,
            "explanation": explanation
        });
    }
}
