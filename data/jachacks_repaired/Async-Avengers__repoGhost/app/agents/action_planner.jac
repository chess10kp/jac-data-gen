import from app.services.llm_runtime { llm }
import from app.models.core { FileMatch, MeetingSummary }
import from app.models.workflow { WorkflowRequest, ExecutionPlanningContext }
import from app.models.outputs { ActionPlan, TaskItem }


def collect_dependencies(planning: ExecutionPlanningContext) -> list[str] {
    deps: list[str] = [];
    for item in planning.blocker_titles[0:4] {
        deps.append(item);
    }
    if len(deps) == 0 {
        deps = ["repo access", "meeting context", "planning context"];
    }
    return deps;
}

def short_task_text(text: str) -> str {
    trimmed: str = text.strip();
    return trimmed;
}

def replace_text(text: str, old: str, new_text: str) -> str {
    return text.replace(old, new_text);
}

def lower_text(text: str) -> str {
    return text.lower();
}

def split_once(text: str, token: str) -> list[str] {
    return text.split(token, 1);
}

def clean_transcript_phrase(text: str) -> str {
    cleaned: str = short_task_text(text);
    if ":" in cleaned {
        parts: list[str] = split_once(cleaned, ":");
        if len(parts) > 1 and len(parts[0]) <= 28 {
            cleaned = short_task_text(parts[1]);
        }
    }
    prefixes: list[str] = [
        "immediate next steps include ",
        "next steps include ",
        "the main goal for this meeting is to ",
        "the team discussed ",
        "the team should ",
        "we should ",
        "we need to ",
        "need to ",
        "let's ",
        "please ",
        "todo ",
        "action item ",
        "next step "
    ];
    lowered: str = lower_text(cleaned);
    for prefix in prefixes {
        if lowered.startswith(prefix) {
            cleaned = short_task_text(cleaned[len(prefix):]);
            lowered = lower_text(cleaned);
        }
    }
    while cleaned.endswith(".") or cleaned.endswith(",") or cleaned.endswith(";") {
        cleaned = cleaned[:len(cleaned) - 1];
    }
    return short_task_text(cleaned);
}

def expanded_action_phrases(action_items: list[str]) -> list[str] {
    phrases: list[str] = [];
    seen: list[str] = [];
    for item in action_items {
        normalized: str = clean_transcript_phrase(item);
        if not normalized {
            continue;
        }
        expanded: str = normalized;
        if "," in expanded {
            expanded = replace_text(expanded, ", and ", ", ");
            expanded = replace_text(expanded, " and ", ", ");
        }
        for part in expanded.split(",") {
            phrase: str = clean_transcript_phrase(part);
            lowered: str = lower_text(phrase);
            if len(phrase) < 4 {
                continue;
            }
            if lowered in seen {
                continue;
            }
            if lowered.startswith("ensure ") and len(phrases) > 0 {
                continue;
            }
            if "main goal for this meeting" in lowered or "the team discussed" in lowered {
                continue;
            }
            phrases.append(phrase);
            seen.append(lowered);
            if len(phrases) >= 6 {
                return phrases;
            }
        }
    }
    return phrases;
}

def capitalize_first(text: str) -> str {
    if not text {
        return "";
    }
    return text.capitalize();
}

def normalized_task_title(text: str) -> str {
    title: str = clean_transcript_phrase(text);
    replacements: list[list[str]] = [
        ["finalizing ", "Finalize "],
        ["cleaning up ", "Clean up "],
        ["validating ", "Validate "],
        ["improving ", "Improve "],
        ["conducting ", "Conduct "],
        ["reviewing ", "Review "],
        ["preparing ", "Prepare "],
        ["updating ", "Update "],
        ["adding ", "Add "],
        ["fixing ", "Fix "],
        ["confirming ", "Confirm "],
        ["locking in ", "Lock in "],
        ["stabilizing ", "Stabilize "]
    ];
    lowered: str = lower_text(title);
    for pair in replacements {
        prefix: str = pair[0];
        next_prefix: str = pair[1];
        if lowered.startswith(prefix) {
            title = next_prefix + title[len(prefix):];
            return short_task_text(title);
        }
    }
    return capitalize_first(title);
}

def task_summary_text(focus: str, file_slice: list[str], has_blockers: bool) -> str {
    area_hint: str = focus if focus else "the current repo surface";
    file_hint: str = file_slice[0] if len(file_slice) > 0 else "";
    summary: str = "Scope this workstream in " + area_hint;
    if file_hint {
        summary = summary + ", starting with " + file_hint;
    }
    summary = summary + ", and leave it ready for validation.";
    if has_blockers {
        summary = summary + " Resolve the linked blocker before widening the slice.";
    }
    return summary;
}

def task_file_slice(files: list[FileMatch], offset: int, size: int = 2) -> list[str] {
    picked: list[str] = [];
    for item in files[offset:] {
        if len(picked) >= size {
            break;
        }
        picked.append(item.path);
    }
    return picked;
}

def task_focus_label(planning: ExecutionPlanningContext, files: list[FileMatch], index: int = 0) -> str {
    if len(planning.resolved_areas) > index {
        return planning.resolved_areas[index];
    }
    if len(files) > index {
        return files[index].path;
    }
    return "the current repo surface";
}

def plan_headline(request: WorkflowRequest, files: list[FileMatch]) -> str {
    if request.mode == "review_prep" {
        return "RepoGhost prepared a reviewer-focused execution plan from repo, meeting, graph, and planning context.";
    }
    return "RepoGhost generated a staged execution plan from " + str(len(files)) + " repo-grounded files and the merged planning context.";
}

def plan_first_task(request: WorkflowRequest, planning: ExecutionPlanningContext, files: list[FileMatch]) -> str {
    if request.mode == "standup" {
        return "Summarize completed context-building and reasoning work for the team update.";
    }
    if request.mode == "handoff" {
        return "Capture the current state of the repo, planning context, and open risks.";
    }
    if request.mode == "review_prep" {
        return "Group changed areas and risk hotspots into a reviewer-friendly scope.";
    }
    if len(planning.resolved_areas) > 0 {
        return "Inspect " + planning.resolved_areas[0] + " and confirm the implementation boundary.";
    }
    if len(files) > 0 {
        return "Inspect " + files[0].path + " and confirm the implementation boundary.";
    }
    return "Validate the top resolved files against the current request.";
}

def plan_next_task(request: WorkflowRequest) -> str {
    if request.mode == "standup" {
        return "Highlight the next execution slice and any blockers that need owner follow-up.";
    }
    if request.mode == "handoff" {
        return "Package next actions for the incoming developer with likely files and dependencies.";
    }
    if request.mode == "review_prep" {
        return "Generate a checklist grounded in blockers, impacts, and test gaps.";
    }
    return "Turn the planning context into execution-ready tickets and handoff artifacts.";
}


def:pub build_action_plan(request: WorkflowRequest, planning: ExecutionPlanningContext, files: list[FileMatch]) -> ActionPlan {
    return ActionPlan(
        headline=plan_headline(request, files),
        first_task=plan_first_task(request, planning, files),
        next_task=plan_next_task(request),
        phases=["Stage 1 ingest", "Stage 1 merge", "Stage 2 reasoning", "Stage 2 merge", "Stage 3 output generation", "Execution handoff"]
    );
}


def:pub build_action_tasks(request: WorkflowRequest, planning: ExecutionPlanningContext, files: list[FileMatch], meeting: MeetingSummary) -> list[TaskItem] {
    likely_files: list[str] = [];
    for item in files {
        if len(likely_files) >= 5 {
            break;
        }
        likely_files.append(item.path);
    }

    action_phrases: list[str] = [];
    if meeting {
        action_phrases = expanded_action_phrases(meeting.action_items);
    }

    if len(action_phrases) > 0 {
        tasks: list[TaskItem] = [];
        action_index: int = 0;
        for action in action_phrases {
            if len(tasks) >= 6 {
                break;
            }
            focus: str = task_focus_label(planning, files, action_index);
            file_slice: list[str] = task_file_slice(files, action_index, 2);
            title: str = normalized_task_title(action);
            tasks.append(TaskItem(
                title=title,
                summary=task_summary_text(focus, file_slice, action_index == 0 and len(planning.blocker_titles) > 0),
                phase=("Execution Slice " + str(action_index + 1)),
                dependencies=(planning.blocker_titles[0:2] if action_index == 0 else []),
                likely_files=(file_slice if len(file_slice) > 0 else likely_files)
            ));
            action_index = action_index + 1;
        }
        return tasks;
    }

    deps = collect_dependencies(planning);
    tasks: list[TaskItem] = [
        TaskItem(
            title="Lock the primary implementation boundary",
            summary="Pin down the highest-signal repo surface, confirm the main files, and keep the first workstream tightly scoped.",
            phase="Phase A",
            dependencies=deps,
            likely_files=(task_file_slice(files, 0, 3) if len(files) > 0 else planning.resolved_areas[0:4])
        ),
        TaskItem(
            title="Deliver the next project workstream",
            summary="Turn the planning context into a concrete product-facing slice with repo-grounded changes and validation hooks.",
            phase="Phase B",
            dependencies=planning.blocker_titles[0:4],
            likely_files=(task_file_slice(files, 1, 3) if len(files) > 1 else likely_files)
        ),
        TaskItem(
            title="Resolve blockers and validation gaps",
            summary="Close dependency risks, tighten confidence around the riskiest paths, and cover the surfaced test gaps before handoff.",
            phase="Phase C",
            dependencies=(planning.blocker_titles[0:3] if len(planning.blocker_titles) > 0 else ["scoped change set", "risk review"]),
            likely_files=likely_files
        ),
        TaskItem(
            title="Package the run for handoff",
            summary="Align tickets, handoff notes, and review guidance so the current slice is easy to continue without rereading the full transcript.",
            phase="Phase D",
            dependencies=["implemented changes", "validated risk hotspots"],
            likely_files=task_file_slice(files, 0, 2)
        )
    ];
    if request.mode == "meeting_to_tickets" {
        tasks[0].title = "Convert meeting language into execution slices";
        tasks[0].summary = "Turn action items, decisions, and blockers into a prioritized engineering sequence.";
    }
    return tasks;
}

def:pub llm_action_plan(
    _request: WorkflowRequest,
    _planning: ExecutionPlanningContext,
    _files: list[FileMatch],
    _draft: ActionPlan
) -> ActionPlan by llm();

def:pub llm_action_tasks(
    _request: WorkflowRequest,
    _planning: ExecutionPlanningContext,
    _files: list[FileMatch],
    _meeting: MeetingSummary,
    _draft: list[TaskItem]
) -> list[TaskItem] by llm();
