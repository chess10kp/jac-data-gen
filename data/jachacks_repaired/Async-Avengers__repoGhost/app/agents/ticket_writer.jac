import from app.services.llm_runtime { llm }
import from app.models.core { FileMatch }
import from app.models.workflow { WorkflowRequest, ExecutionPlanningContext }
import from app.models.outputs { GeneratedTicket, TaskItem }


def:pub write_tickets(request: WorkflowRequest, planning: ExecutionPlanningContext, tasks: list[TaskItem], files: list[FileMatch]) -> list[GeneratedTicket] {
    likely_files: list[str] = [];
    for item in files[0:6] {
        likely_files.append(item.path);
    }
    blockers: list[str] = [];
    for item in planning.blocker_titles[0:5] {
        blockers.append(item);
    }
    tickets: list[GeneratedTicket] = [];
    for task in tasks[0:3] {
        tickets.append(
            GeneratedTicket(
                title=task.title,
                summary=task.summary,
                priority=("high" if task.phase in ["Phase A", "Phase B"] else "medium"),
                acceptance_criteria=[
                    "Scope is grounded in resolved repo areas",
                    "Dependencies and blockers are explicitly tracked",
                    "Likely files are attached for implementation",
                    "Output is ready to hand to an engineer"
                ],
                likely_files=(task.likely_files if len(task.likely_files) > 0 else likely_files),
                blockers=blockers,
                dependencies=task.dependencies
            )
        );
    }
    if request.mode == "review_prep" {
        tickets.append(
            GeneratedTicket(
                title="Review high-risk changes before merge",
                summary="Use impact hotspots and test gaps to focus reviewer attention on the riskiest areas.",
                priority="high",
                acceptance_criteria=[
                    "Risk hotspots are listed",
                    "Reviewer checklist is attached",
                    "Test gaps are called out"
                ],
                likely_files=likely_files,
                blockers=blockers,
                dependencies=["review scope", "test gap analysis"]
            )
        );
    }
    return tickets;
}

def:pub llm_write_tickets(
    _request: WorkflowRequest,
    _planning: ExecutionPlanningContext,
    _tasks: list[TaskItem],
    _files: list[FileMatch],
    _draft: list[GeneratedTicket]
) -> list[GeneratedTicket] by llm();
