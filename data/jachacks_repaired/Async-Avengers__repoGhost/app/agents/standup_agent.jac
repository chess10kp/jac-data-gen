import from app.services.llm_runtime { llm }
import from app.models.workflow { WorkflowRequest, ExecutionPlanningContext, WorkflowTraceStep }
import from app.models.outputs { StandupUpdateData, TaskItem }
import from app.models.core { MeetingSummary }


def:pub generate_standup(request: WorkflowRequest, planning: ExecutionPlanningContext, tasks: list[TaskItem], trace: list[WorkflowTraceStep], meeting: MeetingSummary) -> StandupUpdateData {
    if request { }
    if tasks { }
    done: list[str] = [
        "Scanned repo and synced docs into project context graph across " + str(len(trace)) + " workflow steps.",
        "Parsed meeting context and merged Stage 2 reasoning into the planning context.",
        "Prepared Stage 3 output artifacts for execution and communication."
    ];

    next_items: list[str] = [];
    if meeting and len(meeting.action_items) > 0 {
        for action in meeting.action_items {
            if len(next_items) >= 5 {
                break;
            }
            next_items.append(action);
        }
    }
    if len(next_items) == 0 and len(planning.resolved_areas) > 0 {
        for area in planning.resolved_areas {
            if len(next_items) >= 3 {
                break;
            }
            next_items.append("Work through " + area + " and confirm scope.");
        }
    }
    if len(next_items) == 0 {
        next_items = [
            "Review the top resolved area and confirm execution boundary.",
            "Address the highest-severity blocker before implementation begins.",
            "Prepare delivery artifacts from the merged planning context."
        ];
    }

    blockers: list[str] = [];
    if meeting and len(meeting.blockers) > 0 {
        for b in meeting.blockers {
            if len(blockers) >= 4 {
                break;
            }
            blockers.append(b.title);
        }
    }
    for title in planning.blocker_titles {
        if len(blockers) >= 4 {
            break;
        }
        if title not in blockers {
            blockers.append(title);
        }
    }
    if len(blockers) == 0 {
        blockers = ["No critical blockers detected — monitor dependency and test-gap risks."];
    }

    return StandupUpdateData(done=done, next=next_items, blockers=blockers);
}

def:pub llm_generate_standup(
    _request: WorkflowRequest,
    _planning: ExecutionPlanningContext,
    _tasks: list[TaskItem],
    _trace: list[WorkflowTraceStep],
    _meeting: MeetingSummary,
    _draft: StandupUpdateData
) -> StandupUpdateData by llm();
