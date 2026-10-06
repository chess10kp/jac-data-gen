import from datetime { datetime }
import from app.models.workflow { WorkflowTraceStep }

def:pub seed_trace() -> list[WorkflowTraceStep] {
    now = str(datetime.now());
    return [
        WorkflowTraceStep(stage="stage_1", agent="Repo Mapper Agent", status="done", started_at=now, finished_at=now, detail="Mapped repo structure and entry points."),
        WorkflowTraceStep(stage="stage_1", agent="Meeting Interpreter Agent", status="done", started_at=now, finished_at=now, detail="Extracted tasks, decisions, blockers, and people."),
        WorkflowTraceStep(stage="stage_1", agent="Code Search Agent", status="done", started_at=now, finished_at=now, detail="Ranked likely files from repo and meeting terms."),
        WorkflowTraceStep(stage="stage_2", agent="Context Resolver Agent", status="running", started_at=now, finished_at="", detail="Resolving vague requests to concrete modules."),
        WorkflowTraceStep(stage="stage_3", agent="Ticket Writer Agent", status="queued", started_at="", finished_at="", detail="Waiting for planning context merge.")
    ];
}
