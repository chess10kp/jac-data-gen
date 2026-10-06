import from app.services.llm_runtime { llm }
import from app.models.core { FileMatch }
import from app.models.workflow { WorkflowRequest, ExecutionPlanningContext }
import from app.models.outputs { ReviewScopeData, TaskItem }


def:pub prepare_review_scope(request: WorkflowRequest, planning: ExecutionPlanningContext, tasks: list[TaskItem], files: list[FileMatch]) -> ReviewScopeData {
    changed_areas: list[str] = [];
    for item in planning.resolved_areas[0:5] {
        changed_areas.append(item);
    }
    for item in files[0:4] {
        if item.path not in changed_areas {
            changed_areas.append(item.path);
        }
    }
    risk_hotspots: list[str] = [];
    for item in planning.impact_insights[0:4] {
        risk_hotspots.append(item.title + " — " + item.detail);
    }
    for item in planning.test_gap_insights[0:3] {
        risk_hotspots.append(item.title + " — " + item.detail);
    }
    checklist: list[str] = [
        "Confirm the scope matches the resolved repo areas.",
        "Review blocker assumptions and dependency impacts.",
        "Check that the riskiest paths have test coverage recommendations.",
        "Verify tickets and handoff notes align with the action plan."
    ];
    for item in tasks[0:2] {
        checklist.append("Review task alignment for " + item.title + ".");
    }
    if request.mode == "review_prep" {
        checklist.append("Focus reviewer attention on the highest-risk hotspots first.");
    }
    return ReviewScopeData(
        summary="RepoGhost prepared a review scope from the merged planning context and likely implementation surface.",
        changed_areas=changed_areas,
        risk_hotspots=risk_hotspots,
        checklist=checklist
    );
}

def:pub llm_prepare_review_scope(
    _request: WorkflowRequest,
    _planning: ExecutionPlanningContext,
    _tasks: list[TaskItem],
    _files: list[FileMatch],
    _draft: ReviewScopeData
) -> ReviewScopeData by llm();
