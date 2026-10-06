import from app.models.core { FileMatch, MeetingSummary, DecisionItem, BlockerItem, OwnershipGuess }
import from app.models.workflow { WorkflowTraceStep, WorkflowRunState, ExecutionPlanningContext, PlanningInsight }

obj RepoSummary {
    has project_name: str = "RepoGhost";
    has overview: str = "";
    has frameworks: list[str] = [];
    has entry_points: list[str] = [];
    has major_dirs: list[str] = [];
    has project_type: str = "";
}

obj TaskItem {
    has title: str = "";
    has summary: str = "";
    has phase: str = "";
    has dependencies: list[str] = [];
    has likely_files: list[str] = [];
}

obj ActionPlan {
    has headline: str = "";
    has first_task: str = "";
    has next_task: str = "";
    has phases: list[str] = [];
}

obj GeneratedTicket {
    has title: str = "";
    has summary: str = "";
    has priority: str = "medium";
    has acceptance_criteria: list[str] = [];
    has likely_files: list[str] = [];
    has blockers: list[str] = [];
    has dependencies: list[str] = [];
}

obj HandoffNoteData {
    has summary: str = "";
    has touched_areas: list[str] = [];
    has risks: list[str] = [];
    has next_actions: list[str] = [];
}

obj StandupUpdateData {
    has done: list[str] = [];
    has next: list[str] = [];
    has blockers: list[str] = [];
}

obj ReviewScopeData {
    has summary: str = "";
    has changed_areas: list[str] = [];
    has risk_hotspots: list[str] = [];
    has checklist: list[str] = [];
}

obj GraphNodeView {
    has id: str = "";
    has kind: str = "";
    has label: str = "";
    has detail: str = "";
    has group: str = "";
}

obj GraphEdgeView {
    has source: str = "";
    has target: str = "";
    has kind: str = "relates_to";
    has detail: str = "";
}

obj ProjectContextGraph {
    has project_id: str = "project";
    has run_id: str = "";
    has nodes: list[GraphNodeView] = [];
    has edges: list[GraphEdgeView] = [];
    has focus_paths: list[str] = [];
    has trace_summary: list[str] = [];
}

obj DocsSyncResult {
    has files: list[FileMatch] = [];
    has decisions: list[DecisionItem] = [];
}

obj QueryArtifactAnswer {
    has answer: str = "";
    has key_points: list[str] = [];
    has relevant_files: list[str] = [];
    has blockers: list[str] = [];
    has next_steps: list[str] = [];
}

def docs_sync_files(result: DocsSyncResult) -> list[FileMatch] {
    return result.files;
}

def docs_sync_decisions(result: DocsSyncResult) -> list[DecisionItem] {
    return result.decisions;
}

obj WorkflowResultBundle {
    has repo_summary: RepoSummary = RepoSummary();
    has meeting_summary: MeetingSummary = MeetingSummary();
    has relevant_files: list[FileMatch] = [];
    has ownership: list[OwnershipGuess] = [];
    has decisions: list[DecisionItem] = [];
    has blockers: list[BlockerItem] = [];
    has planning: ExecutionPlanningContext = ExecutionPlanningContext();
    has action_plan: ActionPlan = ActionPlan();
    has tasks: list[TaskItem] = [];
    has tickets: list[GeneratedTicket] = [];
    has handoff: HandoffNoteData = HandoffNoteData();
    has standup: StandupUpdateData = StandupUpdateData();
    has review: ReviewScopeData = ReviewScopeData();
    has trace: list[WorkflowTraceStep] = [];
    has context_graph: ProjectContextGraph = ProjectContextGraph();
    has run_state: WorkflowRunState = WorkflowRunState();
}

obj RepoGhostViewState {
    has repoPath: str = "";
    has meetingText: str = "";
    has prompt: str = "";
    has draftPrompt: str = "";
    has mode: str = "feature_plan";
    has loading: bool = False;
    has error: str = "";
    has bundle: WorkflowResultBundle | None = None;
    has activeTab: str = "context";
    has chatThread: list[dict[str, str]] = [];
    has lastRunLabel: str = "Ready";
    has statusTone: str = "ready";
    has runState: WorkflowRunState = WorkflowRunState();
    has graphNodes: list[GraphNodeView] = [];
    has graphEdges: list[GraphEdgeView] = [];
    has graphFocusPaths: list[str] = [];
    has planningResolved: list[PlanningInsight] = [];
    has planningBlockers: list[PlanningInsight] = [];
    has planningImpacts: list[PlanningInsight] = [];
    has planningTestGaps: list[PlanningInsight] = [];
    has actionPlanPhases: list[str] = [];
    has ticketTitles: list[str] = [];
    has handoffActions: list[str] = [];
    has reviewHotspots: list[str] = [];
    has submit: any | None = None;
    has setRepoPath: any | None = None;
    has setMeetingText: any | None = None;
    has setDraftPrompt: any | None = None;
    has toggleExpanded: any | None = None;
}
