"""Data ingestion walkers for processing raw input into memory graph nodes."""

import from models.memory { MemoryNode, MemoryEdge, RelationType }

import from datetime { datetime }

def extract_memories(text: str, source_type: str) -> list[dict[str, str]]
    by llm(
        reason="Extract key memories from the provided text. For each memory return a dict with keys: content (str), memory_type (str - one of event/person/emotion/value/theme/decision/habit/preference), importance (str numeric 0-1), timestamp (str or empty string if unknown). Focus on facts, relationships, emotions, values, decisions, and recurring patterns."
    );

def detect_relationships(text: str) -> list[dict[str, str]]
    by llm(
        reason="Detect relationships between people mentioned in the text. For each relationship return a dict with keys: person_a (str), person_b (str), relation (str describing the relationship), sentiment (str numeric -1 to 1), evidence (str quote or paraphrase from text)."
    );

walker IngestText {
    has content: str;
    has source_type: str = "text";
    has source_hash: str = "";
    has memories_created: int = 0;

    can with entry {
        extracted = extract_memories(self.content, self.source_type);
        if not extracted {
            extracted = [];
        }

        for mem in extracted {
            if not mem or not isinstance(mem, dict) {
                continue;
            }
            if "content" not in mem or "memory_type" not in mem {
                continue;
            }
            ts = mem.get("timestamp", "");
            if not ts {
                ts = str(datetime.now());
            }

            new_node = MemoryNode(
                content=mem["content"],
                memory_type=mem["memory_type"],
                timestamp=ts,
                confidence=0.7,
                source_hash=self.source_hash,
                importance=float(mem.get("importance", "0.5")),
                decay_rate=0.01,
                last_accessed=str(datetime.now()),
                access_count=0,
                user_confirmed=False
            );
            here ++> new_node;
            self.memories_created += 1;
        }

        # Detect and encode relationships as edges between person nodes
        relationships = detect_relationships(self.content);
        if not relationships {
            relationships = [];
        }
        person_nodes = [-->][?:MemoryNode, memory_type == "person"];

        for rel in relationships {
            if not rel or not isinstance(rel, dict) {
                continue;
            }
            source_node = None;
            target_node = None;
            for pn in person_nodes {
                if rel.get("person_a", "") in pn.content {
                    source_node = pn;
                }
                if rel.get("person_b", "") in pn.content {
                    target_node = pn;
                }
            }
            if source_node is not None and target_node is not None {
                (source_node as MemoryNode) +>:MemoryEdge: relation_type=RelationType.INVOLVES, strength=abs(float(rel.get("sentiment", "0.5"))), confidence=0.6 :+> (target_node as MemoryNode);
            }
        }

        report self.memories_created;
    }
}

walker IngestConversation {
    has messages: list[dict];
    has source_hash: str = "";
    has memories_created: int = 0;
    has relationships_found: int = 0;

    can with entry {
        # Build full conversation text for extraction
        full_text = "";
        for msg in self.messages {
            sender = msg.get("sender", "unknown");
            content = msg.get("content", "");
            ts = msg.get("timestamp", "");
            full_text += sender + " (" + ts + "): " + content + "\n";
        }

        # Extract topical memories from conversation
        extracted = extract_memories(full_text, "conversation");
        if not extracted {
            extracted = [];
        }
        for mem in extracted {
            if not mem or not isinstance(mem, dict) {
                continue;
            }
            if "content" not in mem or "memory_type" not in mem {
                continue;
            }
            ts = mem.get("timestamp", "");
            if not ts {
                ts = str(datetime.now());
            }

            new_node = MemoryNode(
                content=mem["content"],
                memory_type=mem["memory_type"],
                timestamp=ts,
                confidence=0.65,
                source_hash=self.source_hash,
                importance=float(mem.get("importance", "0.5")),
                decay_rate=0.02,
                last_accessed=str(datetime.now()),
                access_count=0,
                user_confirmed=False
            );
            here ++> new_node;
            self.memories_created += 1;
        }

        # Detect relationships from conversation dynamics
        relationships = detect_relationships(full_text);
        if not relationships {
            relationships = [];
        }
        person_nodes = [-->][?:MemoryNode, memory_type == "person"];

        for rel in relationships {
            if not rel or not isinstance(rel, dict) {
                continue;
            }
            source_node = None;
            target_node = None;
            for pn in person_nodes {
                if rel.get("person_a", "") in pn.content {
                    source_node = pn;
                }
                if rel.get("person_b", "") in pn.content {
                    target_node = pn;
                }
            }
            if source_node is not None and target_node is not None {
                (source_node as MemoryNode) +>:MemoryEdge: relation_type=RelationType.INVOLVES, strength=abs(float(rel.get("sentiment", "0.5"))), confidence=0.55 :+> (target_node as MemoryNode);
                self.relationships_found += 1;
            }
        }

        report {
            "memories_created": self.memories_created,
            "relationships_found": self.relationships_found
        };
    }
}
