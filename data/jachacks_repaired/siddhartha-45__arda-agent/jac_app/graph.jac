"""
ARDA Agent Graph Definition
Core graph structure for the Autonomous Research & Decision Agent
"""

node UserQuery {
    has query: str;
    has timestamp: float;
    has session_id: str;
}

node Task {
    has task_id: str;
    has description: str;
    has status: str;
    has priority: int;
    has created_at: float;
    has assigned_tool: str;
}

node SearchResult {
    has result_id: str;
    has query: str;
    has content: str;
    has source: str;
    has relevance_score: float;
    has timestamp: float;
}

node Analysis {
    has analysis_id: str;
    has task_id: str;
    has analysis_text: str;
    has confidence_score: float;
    has created_at: float;
}

node MemoryEntry {
    has entry_id: str;
    has key: str;
    has value: str;
    has embedding: list;
    has category: str;
    has created_at: float;
}

node ReflectionRecord {
    has reflection_id: str;
    has task_id: str;
    has needs_more_research: bool;
    has confidence: float;
    has feedback: str;
    has created_at: float;
}

node FinalReport {
    has report_id: str;
    has query: str;
    has tasks: list;
    has analyses: list;
    has reflection: str;
    has final_recommendation: str;
    has created_at: float;
}

edge plannedTask {
    has priority: int;
}

edge executionEdge {
    has status: str;
}

edge memoryLink {
    has relevance: float;
}

edge analysisLink {
    has contribution: str;
}

edge reflectionEdge {
    has feedback: str;
}

edge reportLink {
    has summary: str;
}

walker InitializeResearch {
    has initialize: str;
}

walker PlanTasks {
    has plan: str;
}

walker ExecuteTasks {
    has execute: str;
}

walker StoreMemory {
    has store: str;
}

walker ReflectOnResults {
    has reflect: str;
}

walker GenerateReport {
    has generate_report: str;
}

walker MemoryRetrieval {
    has retrieve: str;
}
