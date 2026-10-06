node ProjectNode {
    has name: str = "";
    has repo_path: str = "";
    has summary: str = "";
}

node DirectoryNode { has path: str = ""; has label: str = ""; }
node FileNode { has path: str = ""; has kind: str = ""; has summary: str = ""; }
node ModuleNode { has name: str = ""; has path: str = ""; }
node SymbolNode { has name: str = ""; has kind: str = ""; has signature: str = ""; }
node RepoSummaryNode { has overview: str = ""; }
node MeetingNode { has title: str = ""; has raw_text: str = ""; }
node DecisionNode { has title: str = ""; has detail: str = ""; }
node TaskNode { has title: str = ""; has summary: str = ""; }
node TicketNode { has title: str = ""; has priority: str = "medium"; }
node BlockerNode { has title: str = ""; has severity: str = "medium"; }
node PersonNode { has name: str = ""; has role_hint: str = ""; }
node SessionNode { has session_id: str = ""; has active_mode: str = "feature_plan"; }
node RequestNode { has prompt: str = ""; has mode: str = "feature_plan"; }
node WorkflowRunNode { has run_id: str = ""; has status: str = "pending"; }
node ModeNode { has key: str = ""; has label: str = ""; }
node ResultBundleNode { has label: str = "Workflow Result Bundle"; }
node ReviewScopeNode { has summary: str = ""; }
node HandoffNoteNode { has summary: str = ""; }
node StandupUpdateNode { has summary: str = ""; }
