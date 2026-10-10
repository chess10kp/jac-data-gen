"""
Memory Agent - Manages semantic and persistent memory
"""

import:py from "tools.vector_memory", VectorMemory;
import:py from "tools.db_memory", DatabaseMemory;

walker StoreMemory {
    """
    Stores research findings in semantic and database memory
    """
    has results: list;
    has session_id: str;
    has vector_memory: any;
    has db_memory: any;

    can store_all_results;
    can store_semantic;
    can store_persistent;
    can index_memory;

    :can:init {
        self.vector_memory = VectorMemory();
        self.db_memory = DatabaseMemory();
    }

    :walker:activity {
        self.store_all_results();
    }

    :can:store_all_results {
        """
        Stores all results in both memory systems
        """
        for result in self.results {
            self.store_semantic(result);
            self.store_persistent(result);
        }

        self.index_memory();
    }

    :can:store_semantic {
        """
        Stores results in semantic/vector memory
        """
        has result: dict;

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

    :can:store_persistent {
        """
        Stores results in persistent database memory
        """
        has result: dict;

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

    :can:index_memory {
        """
        Creates semantic indices for fast retrieval
        """
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
    has vector_memory: any;
    has db_memory: any;
    has retrieved_memories: list = [];

    can retrieve_semantic;
    can retrieve_historical;
    can merge_results;

    :can:init {
        self.vector_memory = VectorMemory();
        self.db_memory = DatabaseMemory();
    }

    :walker:activity {
        self.retrieve_semantic();
        self.retrieve_historical();
        self.merge_results();
    }

    :can:retrieve_semantic {
        """
        Retrieves semantically similar memories
        """
        results = self.vector_memory.search(self.query, top_k=5);
        self.retrieved_memories.extend(results);
    }

    :can:retrieve_historical {
        """
        Retrieves historical memory from database
        """
        results = self.db_memory.query_by_session(self.session_id, limit=10);
        self.retrieved_memories.extend(results);
    }

    :can:merge_results {
        """
        Merges and deduplicates retrieved memories
        """
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
