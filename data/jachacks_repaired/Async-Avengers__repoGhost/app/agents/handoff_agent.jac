import from app.services.llm_runtime { llm }
import from app.models.core { FileMatch }
import from app.models.workflow { WorkflowRequest, ExecutionPlanningContext }
import from app.models.outputs { HandoffNoteData, TaskItem }


def:pub generate_handoff(request: WorkflowRequest, planning: ExecutionPlanningContext, tasks: list[TaskItem], files: list[FileMatch]) -> HandoffNoteData {
    touched_areas: list[str] = [];
    for item in planning.resolved_areas[0:5] {
        touched_areas.append(item);
    }
    if len(touched_areas) == 0 {
        for item in files[0:4] {
            touched_areas.append(item.path);
        }
    }
    risks: list[str] = [];
    for item in planning.blocker_insights[0:4] {
        risks.append(item.title + " — " + item.detail);
    }
    if len(risks) == 0 {
        risks = ["No critical blockers detected; validate downstream impact before implementation." ];
    }
    next_actions: list[str] = [];
    for task in tasks[0:4] {
        next_actions.append(task.title + ": " + task.summary);
    }
    return HandoffNoteData(
        summary="RepoGhost prepared a " + request.mode + " handoff grounded in the repo scan, meeting context, unified graph, and execution planning context.",
        touched_areas=touched_areas,
        risks=risks,
        next_actions=next_actions
    );
}

def:pub llm_generate_handoff(
    _request: WorkflowRequest,
    _planning: ExecutionPlanningContext,
    _tasks: list[TaskItem],
    _files: list[FileMatch],
    _draft: HandoffNoteData
) -> HandoffNoteData by llm();
