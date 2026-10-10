"""Memory recall walkers for querying and retrieving relevant memories."""

include models.memory;

import from datetime { datetime }

def score_relevance(query: str, memory_content: str) -> float
    by llm(
        reason="Score how relevant the memory content is to the query on a scale of 0.0 to 1.0. Consider semantic similarity, topical overlap, and contextual relevance. Return only a float value."
    );

walker RecallMemories {
    has query: str;
    has max_results: int = 10;
    has min_relevance: float = 0.3;
    has recalled: list[dict] = [];

    can with entry {
        visit [-->][?:MemoryNode];
    }

    can with MemoryNode entry {
        relevance = score_relevance(self.query, here.content);

        if relevance >= self.min_relevance {
            self.recalled.append({
                "content": here.content,
                "memory_type": str(here.memory_type),
                "timestamp": here.timestamp,
                "importance": here.importance,
                "confidence": here.confidence,
                "relevance": relevance,
                "access_count": here.access_count
            });

            # Update access metadata
            here.access_count += 1;
            here.last_accessed = str(datetime.now());

            # Traverse connected nodes to find associatively linked memories
            visit [-->][?:MemoryNode];
        }
    }

    can on_exit with `root exit {
        # Sort by relevance descending and trim to max_results
        self.recalled = sorted(
            self.recalled,
            key=lambda m: m["relevance"],
            reverse=True
        )[:self.max_results];

        report self.recalled;
    }
}
