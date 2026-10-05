"""
Memory Agent - Manages semantic and persistent memory
"""

import json;
import time;
import from tools.vector_memory { VectorMemory }
import from tools.db_memory { DatabaseMemory }

walker StoreMemory {
    """
    Stores research findings in semantic and database memory
    """
    has results: list;
    has session_id: str;
    has vector_memory: any = None;
    has db_memory: any = None;

    def init {
        self.vector_memory = VectorMemory();
        self.db_memory = DatabaseMemory();
    }

    can with Root entry {
        self.store_all_results();
    }

    def store_all_results {
        for result in self.results {
            self.store_semantic(result);
            self.store_persistent(result);
        }

        self.index_memory();
    }

    def store_semantic(result: dict) {
        task_id = result.get('task_id');
        content = result.get('analysis', result.get('search_results', ''));

        if content {
            entry_id = f"{self.session_id}_{task_id}";

            self.vector_memory.add(
                entry_id=entry_id,
                text=str(content),
                metadata={
                    'task_id': task_id,
                    'session_id': self.session_id,
                    'timestamp': time.time(),
                    'type': result.get('type', 'analysis')
                }
            );
        }
    }

    def store_persistent(result: dict) {
        task_id = result.get('task_id');
        status = result.get('status');
        content = result.get('analysis', json.dumps(result.get('search_results', [])));

        memory_entry = {
            'session_id': self.session_id,
            'task_id': task_id,
            'content': content,
            'status': status,
            'timestamp': time.time(),
            'type': result.get('type', 'result')
        };

        self.db_memory.insert(memory_entry);
    }

    def index_memory {
        self.vector_memory.build_index();
        report f"Memory indexed for session {self.session_id}";
    }
}

walker MemoryRetrieval {
    """
    Retrieves relevant information from memory
    """
    has query: str;
    has session_id: str;
    has vector_memory: any = None;
    has db_memory: any = None;
    has retrieved_memories: list = [];

    def init {
        self.vector_memory = VectorMemory();
        self.db_memory = DatabaseMemory();
    }

    can with Root entry {
        self.retrieve_semantic();
        self.retrieve_historical();
        self.merge_results();
    }

    def retrieve_semantic {
        results = self.vector_memory.search(self.query, top_k=5);
        self.retrieved_memories.extend(results);
    }

    def retrieve_historical {
        results = self.db_memory.query_by_session(self.session_id, limit=10);
        self.retrieved_memories.extend(results);
    }

    def merge_results {
        seen = set();
        unique_memories = [];

        for memory in self.retrieved_memories {
            memory_key = memory.get('entry_id', memory.get('task_id', ''));
            if memory_key not in seen {
                seen.add(memory_key);
                unique_memories.append(memory);
            }
        }

        self.retrieved_memories = unique_memories;
    }
}
