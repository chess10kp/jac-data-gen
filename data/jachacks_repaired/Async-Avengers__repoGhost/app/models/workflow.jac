obj WorkflowMode {
    has key: str = "feature_plan";
    has label: str = "Feature Planning";
    has description: str = "Plan work from repo and meeting context.";
}

obj WorkflowTraceStep {
    has stage: str = "stage_1";
    has agent: str = "Repo Mapper Agent";
    has status: str = "pending";
    has started_at: str = "";
    has finished_at: str = "";
    has detail: str = "";
    has execution_mode: str = "deterministic";
    has model_name: str = "";
    has fallback_reason: str = "";
}

obj WorkflowRequest {
    has repo_path: str = "";
    has meeting_text: str = "";
    has prompt: str = "";
    has mode: str = "feature_plan";
    has user_api_key: str = "";
    has user_model: str = "";
}

obj WorkflowRunState {
    has run_id: str = "";
    has mode: str = "feature_plan";
    has kind: str = "full_run";
    has status: str = "idle";
    has summary: str = "";
    has execution_mode: str = "fallback";
    has model_name: str = "";
    has fallback_reason: str = "";
}

obj PlanningInsight {
    has title: str = "";
    has detail: str = "";
    has severity: str = "medium";
    has category: str = "context";
}

obj ExecutionPlanningContext {
    has resolved_areas: list[str] = [];
    has impacts: list[str] = [];
    has test_gaps: list[str] = [];
    has blocker_titles: list[str] = [];
    has resolved_mappings: list[PlanningInsight] = [];
    has blocker_insights: list[PlanningInsight] = [];
    has impact_insights: list[PlanningInsight] = [];
    has test_gap_insights: list[PlanningInsight] = [];
}
