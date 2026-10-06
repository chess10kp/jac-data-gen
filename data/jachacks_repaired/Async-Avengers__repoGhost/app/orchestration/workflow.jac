import from datetime { datetime }
import from os { path }
import from typing { cast }
import json;
import from byllm.exceptions { ByLLMError }
import from app.models.workflow {
    WorkflowRequest, WorkflowTraceStep, WorkflowRunState,
    ExecutionPlanningContext, PlanningInsight
}
import from app.models.core {
    DecisionItem, BlockerItem, FileMatch, MeetingSummary, OwnershipGuess
}
import from app.models.outputs {
    ActionPlan, DocsSyncResult, GeneratedTicket, HandoffNoteData, QueryArtifactAnswer, RepoSummary,
    ReviewScopeData, ProjectContextGraph, StandupUpdateData, TaskItem,
    WorkflowResultBundle
}
import from app.services.llm_runtime {
    llm, llm_available, llm_model_name, llm_unavailable_reason,
    configure_request_llm
}
import from app.services.memory_store {
    remember_session, update_project_memory, get_project_memory
}
import from app.services.repo_ingest { scan_repo }
import from app.graph.builder { build_stage_one_seed_graph, finalize_context_graph }
include app.agents.repo_mapper;
include app.agents.meeting_interpreter;
include app.agents.code_search;
include app.agents.docs_sync;
import from app.agents.context_resolver { resolve_context }
import from app.agents.blocker_detector { detect_blockers }
import from app.agents.dependency_impact { analyze_dependency_impact }
import from app.agents.test_gap { identify_test_gaps }
include app.agents.action_planner;
include app.agents.ticket_writer;
include app.agents.standup_agent;
include app.agents.handoff_agent;
include app.agents.review_prep;

def llm_query_run_artifacts(_prompt: str, _artifact_context: str) -> QueryArtifactAnswer by llm();

def now_text() -> str {
    return str(datetime.now());
}

def replace_text(text: str, old: str, replacement: str) -> str {
    return text.replace(old, replacement);
}

def lower_text(text: str) -> str {
    return text.lower();
}

def trace_step(
    stage: str,
    agent: str,
    detail: str,
    execution_mode: str = "deterministic",
    fallback_reason: str = "",
    model_name: str = ""
) -> WorkflowTraceStep {
    started: str = now_text();
    return WorkflowTraceStep(
        stage=stage,
        agent=agent,
        status="done",
        started_at=started,
        finished_at=started,
        detail=detail,
        execution_mode=execution_mode,
        model_name=model_name,
        fallback_reason=fallback_reason
    );
}

def slice_text(text: str, limit: int) -> str {
    if len(text) <= limit {
        return text;
    }
    return text[:limit];
}

def join_lines(lines: list[str]) -> str {
    text: str = "";
    for item in lines {
        if not item {
            continue;
        }
        if text {
            text = text + "\n";
        }
        text = text + item;
    }
    return text;
}

def limited_files(files: list[FileMatch], limit: int) -> list[FileMatch] {
    trimmed: list[FileMatch] = [];
    for item in files {
        if len(trimmed) >= limit {
            break;
        }
        trimmed.append(item);
    }
    return trimmed;
}

def find_file_match(candidates: list[FileMatch], match_path: str) -> FileMatch | None {
    for item in candidates {
        if item.path == match_path {
            return item;
        }
    }
    return None;
}

def merged_reranked_files(candidates: list[FileMatch], reranked: list[FileMatch], limit: int = 24) -> list[FileMatch] {
    merged: list[FileMatch] = [];
    seen_paths: list[str] = [];

    for item in reranked {
        if len(merged) >= limit {
            break;
        }
        known: FileMatch | None = find_file_match(candidates, item.path);
        if known is None or item.path in seen_paths {
            continue;
        }
        merged.append(
            FileMatch(
                path=known.path,
                score=(item.score if item.score > 0.0 else known.score),
                rationale=(item.rationale if item.rationale else known.rationale),
                kind=known.kind
            )
        );
        seen_paths.append(item.path);
    }

    for item in candidates {
        if len(merged) >= limit {
            break;
        }
        if item.path in seen_paths {
            continue;
        }
        merged.append(item);
        seen_paths.append(item.path);
    }

    return merged;
}

def read_repo_text(repo_path: str, rel_path: str, content_cache: dict[str, str] | None = None) -> str {
    full_path: str = path.join(repo_path, rel_path.replace("/", path.sep));
    if content_cache is not None and full_path in content_cache {
        return content_cache[full_path];
    }
    text: str = "";
    try {
        with open(full_path, "r", encoding="utf-8", errors="ignore") as handle {
            text = handle.read();
        }
    } except OSError {
        text = "";
    } except UnicodeError {
        text = "";
    }
    if content_cache is not None {
        content_cache[full_path] = text;
    }
    return text;
}

def normalized_doc_decisions(doc_path: str, items: list[DecisionItem]) -> list[DecisionItem] {
    normalized: list[DecisionItem] = [];
    for item in items {
        title: str = item.title if item.title else "Documentation context";
        detail: str = item.detail if item.detail else "Documentation context extracted from " + doc_path + ".";
        confidence: float = item.confidence if item.confidence > 0.0 else 0.68;
        source: str = item.source if item.source else doc_path;
        normalized.append(
            DecisionItem(title=title, detail=detail, confidence=confidence, source=source)
        );
    }
    return normalized;
}

obj RepoSummaryOutcome {
    has summary: RepoSummary = RepoSummary();
    has mode: str = "deterministic";
    has reason: str = "";
}

obj MeetingSummaryOutcome {
    has summary: MeetingSummary = MeetingSummary();
    has mode: str = "deterministic";
    has reason: str = "";
}

obj FileMatchesOutcome {
    has files: list[FileMatch] = [];
    has mode: str = "deterministic";
    has reason: str = "";
}

obj DecisionItemsOutcome {
    has decisions: list[DecisionItem] = [];
    has mode: str = "deterministic";
    has reason: str = "";
}

obj ActionPlanOutcome {
    has plan: ActionPlan = ActionPlan();
    has mode: str = "deterministic";
    has reason: str = "";
}

obj TasksOutcome {
    has tasks: list[TaskItem] = [];
    has mode: str = "deterministic";
    has reason: str = "";
}

obj TicketsOutcome {
    has tickets: list[GeneratedTicket] = [];
    has mode: str = "deterministic";
    has reason: str = "";
}

obj StandupOutcome {
    has standup: StandupUpdateData = StandupUpdateData();
    has mode: str = "deterministic";
    has reason: str = "";
}

obj HandoffOutcome {
    has handoff: HandoffNoteData = HandoffNoteData();
    has mode: str = "deterministic";
    has reason: str = "";
}

obj ReviewOutcome {
    has review: ReviewScopeData = ReviewScopeData();
    has mode: str = "deterministic";
    has reason: str = "";
}

def repo_mapper_fallback_reason(error_text: str) -> str {
    return "Repo Mapper Agent fell back to deterministic summarization: " + error_text;
}

def meeting_fallback_reason(error_text: str) -> str {
    return "Meeting Interpreter Agent fell back to deterministic parsing: " + error_text;
}

def code_search_fallback_reason(error_text: str) -> str {
    return "Code Search Agent kept deterministic ranking after rerank failure: " + error_text;
}

def docs_fallback_reason(error_text: str) -> str {
    return "Docs Sync Agent kept deterministic extraction after LLM failure: " + error_text;
}

def action_plan_fallback_reason(error_text: str) -> str {
    return "Action Planner Agent fell back to deterministic planning: " + error_text;
}

def tasks_fallback_reason(error_text: str) -> str {
    return "Action Planner task generation fell back to deterministic tasks: " + error_text;
}

def tickets_fallback_reason(error_text: str) -> str {
    return "Ticket Writer Agent fell back to deterministic tickets: " + error_text;
}

def standup_fallback_reason(error_text: str) -> str {
    return "Standup Agent fell back to deterministic output: " + error_text;
}

def handoff_fallback_reason(error_text: str) -> str {
    return "Handoff Agent fell back to deterministic output: " + error_text;
}

def review_fallback_reason(error_text: str) -> str {
    return "PR Review Prep Agent fell back to deterministic output: " + error_text;
}

def enrich_repo_summary(repo_path: str, scanned_files: list[FileMatch], draft: RepoSummary) -> RepoSummaryOutcome {
    outcome: RepoSummaryOutcome = RepoSummaryOutcome(summary=draft);
    if len(scanned_files) == 0 {
        return outcome;
    }
    if not llm_available() {
        outcome.mode = "fallback";
        outcome.reason = llm_unavailable_reason();
        return outcome;
    }
    try {
        outcome.summary = llm_repo_mapper(repo_path, limited_files(scanned_files, 16), draft);
        outcome.mode = "llm";
    } except ByLLMError as e {
        outcome.mode = "fallback";
        outcome.reason = repo_mapper_fallback_reason(str(e));
    } except RuntimeError as e {
        outcome.mode = "fallback";
        outcome.reason = repo_mapper_fallback_reason(str(e));
    } except ValueError as e {
        outcome.mode = "fallback";
        outcome.reason = repo_mapper_fallback_reason(str(e));
    } except TypeError as e {
        outcome.mode = "fallback";
        outcome.reason = repo_mapper_fallback_reason(str(e));
    } except OSError as e {
        outcome.mode = "fallback";
        outcome.reason = repo_mapper_fallback_reason(str(e));
    }
    return outcome;
}

def enrich_meeting_summary(meeting_text: str, draft: MeetingSummary) -> MeetingSummaryOutcome {
    outcome: MeetingSummaryOutcome = MeetingSummaryOutcome(summary=draft);
    if not meeting_text {
        return outcome;
    }
    if not llm_available() {
        outcome.mode = "fallback";
        outcome.reason = llm_unavailable_reason();
        return outcome;
    }
    try {
        outcome.summary = llm_meeting_interpreter(slice_text(meeting_text, 9000), draft);
        outcome.mode = "llm";
    } except ByLLMError as e {
        outcome.mode = "fallback";
        outcome.reason = meeting_fallback_reason(str(e));
    } except RuntimeError as e {
        outcome.mode = "fallback";
        outcome.reason = meeting_fallback_reason(str(e));
    } except ValueError as e {
        outcome.mode = "fallback";
        outcome.reason = meeting_fallback_reason(str(e));
    } except TypeError as e {
        outcome.mode = "fallback";
        outcome.reason = meeting_fallback_reason(str(e));
    } except OSError as e {
        outcome.mode = "fallback";
        outcome.reason = meeting_fallback_reason(str(e));
    }
    return outcome;
}

def rerank_relevant_files(prompt: str, meeting_text: str, relevant_files: list[FileMatch]) -> FileMatchesOutcome {
    outcome: FileMatchesOutcome = FileMatchesOutcome(files=relevant_files);
    if not llm_available() or len(relevant_files) == 0 or not (prompt or meeting_text) {
        return outcome;
    }
    try {
        reranked: list[FileMatch] = llm_rerank_code_search(
            prompt,
            slice_text(meeting_text, 4000),
            limited_files(relevant_files, 16)
        );
        outcome.files = merged_reranked_files(relevant_files, reranked, 24);
        outcome.mode = "hybrid";
    } except ByLLMError as e {
        outcome.reason = code_search_fallback_reason(str(e));
    } except RuntimeError as e {
        outcome.reason = code_search_fallback_reason(str(e));
    } except ValueError as e {
        outcome.reason = code_search_fallback_reason(str(e));
    } except TypeError as e {
        outcome.reason = code_search_fallback_reason(str(e));
    } except OSError as e {
        outcome.reason = code_search_fallback_reason(str(e));
    }
    return outcome;
}

def enrich_doc_decisions(
    repo_path: str,
    doc_files: list[FileMatch],
    doc_decisions: list[DecisionItem],
    content_cache: dict[str, str] | None = None
) -> DecisionItemsOutcome {
    outcome: DecisionItemsOutcome = DecisionItemsOutcome(decisions=doc_decisions);
    if len(doc_files) == 0 or not llm_available() {
        return outcome;
    }
    futures: list[list[DecisionItem]] = [];
    future_files: list[FileMatch] = [];
    try {
        for doc_file in doc_files[:4] {
            doc_text: str = slice_text(read_repo_text(repo_path, doc_file.path, content_cache), 6000);
            if not doc_text {
                continue;
            }
            draft_items: list[DecisionItem] = [];
            for item in doc_decisions {
                if item.source == doc_file.path {
                    draft_items.append(item);
                }
            }
            futures.append(llm_extract_doc_decisions(doc_file.path, doc_text, draft_items));
            future_files.append(doc_file);
        }
        enriched_decisions: list[DecisionItem] = [];
        for (index, future) in enumerate(futures) {
            llm_items: list[DecisionItem] = cast(list[DecisionItem], future);
            for item in normalized_doc_decisions(future_files[index].path, llm_items) {
                enriched_decisions.append(item);
            }
        }
        if len(enriched_decisions) > 0 {
            outcome.decisions = enriched_decisions;
            outcome.mode = "hybrid";
        }
    } except ByLLMError as e {
        outcome.reason = docs_fallback_reason(str(e));
    } except RuntimeError as e {
        outcome.reason = docs_fallback_reason(str(e));
    } except ValueError as e {
        outcome.reason = docs_fallback_reason(str(e));
    } except TypeError as e {
        outcome.reason = docs_fallback_reason(str(e));
    } except OSError as e {
        outcome.reason = docs_fallback_reason(str(e));
    }
    return outcome;
}

def enrich_action_plan(
    request: WorkflowRequest,
    planning: ExecutionPlanningContext,
    merged_files: list[FileMatch],
    draft: ActionPlan
) -> ActionPlanOutcome {
    outcome: ActionPlanOutcome = ActionPlanOutcome(plan=draft);
    if not llm_available() {
        outcome.mode = "fallback";
        outcome.reason = llm_unavailable_reason();
        return outcome;
    }
    try {
        outcome.plan = llm_action_plan(request, planning, limited_files(merged_files, 12), draft);
        outcome.mode = "llm";
    } except ByLLMError as e {
        outcome.mode = "fallback";
        outcome.reason = action_plan_fallback_reason(str(e));
    } except RuntimeError as e {
        outcome.mode = "fallback";
        outcome.reason = action_plan_fallback_reason(str(e));
    } except ValueError as e {
        outcome.mode = "fallback";
        outcome.reason = action_plan_fallback_reason(str(e));
    } except TypeError as e {
        outcome.mode = "fallback";
        outcome.reason = action_plan_fallback_reason(str(e));
    } except OSError as e {
        outcome.mode = "fallback";
        outcome.reason = action_plan_fallback_reason(str(e));
    }
    return outcome;
}

def enrich_action_tasks(
    request: WorkflowRequest,
    planning: ExecutionPlanningContext,
    merged_files: list[FileMatch],
    meeting_summary: MeetingSummary,
    draft: list[TaskItem]
) -> TasksOutcome {
    outcome: TasksOutcome = TasksOutcome(tasks=draft);
    if not llm_available() {
        outcome.mode = "fallback";
        outcome.reason = llm_unavailable_reason();
        return outcome;
    }
    try {
        outcome.tasks = llm_action_tasks(request, planning, limited_files(merged_files, 12), meeting_summary, draft);
        outcome.mode = "llm";
    } except ByLLMError as e {
        outcome.mode = "fallback";
        outcome.reason = tasks_fallback_reason(str(e));
    } except RuntimeError as e {
        outcome.mode = "fallback";
        outcome.reason = tasks_fallback_reason(str(e));
    } except ValueError as e {
        outcome.mode = "fallback";
        outcome.reason = tasks_fallback_reason(str(e));
    } except TypeError as e {
        outcome.mode = "fallback";
        outcome.reason = tasks_fallback_reason(str(e));
    } except OSError as e {
        outcome.mode = "fallback";
        outcome.reason = tasks_fallback_reason(str(e));
    }
    return outcome;
}

def enrich_tickets(
    request: WorkflowRequest,
    planning: ExecutionPlanningContext,
    tasks: list[TaskItem],
    merged_files: list[FileMatch],
    draft: list[GeneratedTicket]
) -> TicketsOutcome {
    outcome: TicketsOutcome = TicketsOutcome(tickets=draft);
    if not llm_available() {
        outcome.mode = "fallback";
        outcome.reason = llm_unavailable_reason();
        return outcome;
    }
    try {
        outcome.tickets = llm_write_tickets(request, planning, tasks, limited_files(merged_files, 12), draft);
        outcome.mode = "llm";
    } except ByLLMError as e {
        outcome.mode = "fallback";
        outcome.reason = tickets_fallback_reason(str(e));
    } except RuntimeError as e {
        outcome.mode = "fallback";
        outcome.reason = tickets_fallback_reason(str(e));
    } except ValueError as e {
        outcome.mode = "fallback";
        outcome.reason = tickets_fallback_reason(str(e));
    } except TypeError as e {
        outcome.mode = "fallback";
        outcome.reason = tickets_fallback_reason(str(e));
    } except OSError as e {
        outcome.mode = "fallback";
        outcome.reason = tickets_fallback_reason(str(e));
    }
    return outcome;
}

def enrich_standup(
    request: WorkflowRequest,
    planning: ExecutionPlanningContext,
    tasks: list[TaskItem],
    trace: list[WorkflowTraceStep],
    meeting_summary: MeetingSummary,
    draft: StandupUpdateData
) -> StandupOutcome {
    outcome: StandupOutcome = StandupOutcome(standup=draft);
    if not llm_available() {
        outcome.mode = "fallback";
        outcome.reason = llm_unavailable_reason();
        return outcome;
    }
    try {
        outcome.standup = llm_generate_standup(request, planning, tasks, trace, meeting_summary, draft);
        outcome.mode = "llm";
    } except ByLLMError as e {
        outcome.mode = "fallback";
        outcome.reason = standup_fallback_reason(str(e));
    } except RuntimeError as e {
        outcome.mode = "fallback";
        outcome.reason = standup_fallback_reason(str(e));
    } except ValueError as e {
        outcome.mode = "fallback";
        outcome.reason = standup_fallback_reason(str(e));
    } except TypeError as e {
        outcome.mode = "fallback";
        outcome.reason = standup_fallback_reason(str(e));
    } except OSError as e {
        outcome.mode = "fallback";
        outcome.reason = standup_fallback_reason(str(e));
    }
    return outcome;
}

def enrich_handoff(
    request: WorkflowRequest,
    planning: ExecutionPlanningContext,
    tasks: list[TaskItem],
    merged_files: list[FileMatch],
    draft: HandoffNoteData
) -> HandoffOutcome {
    outcome: HandoffOutcome = HandoffOutcome(handoff=draft);
    if not llm_available() {
        outcome.mode = "fallback";
        outcome.reason = llm_unavailable_reason();
        return outcome;
    }
    try {
        outcome.handoff = llm_generate_handoff(request, planning, tasks, limited_files(merged_files, 12), draft);
        outcome.mode = "llm";
    } except ByLLMError as e {
        outcome.mode = "fallback";
        outcome.reason = handoff_fallback_reason(str(e));
    } except RuntimeError as e {
        outcome.mode = "fallback";
        outcome.reason = handoff_fallback_reason(str(e));
    } except ValueError as e {
        outcome.mode = "fallback";
        outcome.reason = handoff_fallback_reason(str(e));
    } except TypeError as e {
        outcome.mode = "fallback";
        outcome.reason = handoff_fallback_reason(str(e));
    } except OSError as e {
        outcome.mode = "fallback";
        outcome.reason = handoff_fallback_reason(str(e));
    }
    return outcome;
}

def enrich_review_scope(
    request: WorkflowRequest,
    planning: ExecutionPlanningContext,
    tasks: list[TaskItem],
    merged_files: list[FileMatch],
    draft: ReviewScopeData
) -> ReviewOutcome {
    outcome: ReviewOutcome = ReviewOutcome(review=draft);
    if not llm_available() {
        outcome.mode = "fallback";
        outcome.reason = llm_unavailable_reason();
        return outcome;
    }
    try {
        outcome.review = llm_prepare_review_scope(request, planning, tasks, limited_files(merged_files, 12), draft);
        outcome.mode = "llm";
    } except ByLLMError as e {
        outcome.mode = "fallback";
        outcome.reason = review_fallback_reason(str(e));
    } except RuntimeError as e {
        outcome.mode = "fallback";
        outcome.reason = review_fallback_reason(str(e));
    } except ValueError as e {
        outcome.mode = "fallback";
        outcome.reason = review_fallback_reason(str(e));
    } except TypeError as e {
        outcome.mode = "fallback";
        outcome.reason = review_fallback_reason(str(e));
    } except OSError as e {
        outcome.mode = "fallback";
        outcome.reason = review_fallback_reason(str(e));
    }
    return outcome;
}

def first_fallback_reason(trace: list[WorkflowTraceStep]) -> str {
    for step in trace {
        if step.fallback_reason {
            return step.fallback_reason;
        }
    }
    return "";
}

def aggregate_execution_mode(trace: list[WorkflowTraceStep]) -> str {
    has_llm: bool = False;
    has_hybrid: bool = False;
    has_fallback: bool = False;
    has_deterministic: bool = False;
    for step in trace {
        if step.execution_mode == "llm" {
            has_llm = True;
        } elif step.execution_mode == "hybrid" {
            has_hybrid = True;
        } elif step.execution_mode == "fallback" {
            has_fallback = True;
        } else {
            has_deterministic = True;
        }
        if step.fallback_reason {
            has_fallback = True;
        }
    }
    if has_fallback {
        return "fallback";
    }
    if has_hybrid or (has_llm and has_deterministic) {
        return "hybrid";
    }
    if has_llm {
        return "llm";
    }
    return "fallback";
}

def make_run_state(
    request: WorkflowRequest,
    kind: str,
    summary: str,
    trace: list[WorkflowTraceStep]
) -> WorkflowRunState {
    run_time: str = replace_text(replace_text(now_text(), " ", "T"), ":", "-");
    execution_mode: str = aggregate_execution_mode(trace);
    return WorkflowRunState(
        run_id=kind + "-" + run_time,
        mode=request.mode,
        kind=kind,
        status="completed",
        summary=summary,
        execution_mode=execution_mode,
        model_name=(llm_model_name() if execution_mode in ["llm", "hybrid"] else ""),
        fallback_reason=first_fallback_reason(trace)
    );
}

def dir_area_label(segment: str) -> str {
    if segment in ["components", "component"] { return "UI Components"; }
    if segment in ["pages", "page", "views", "view", "screens"] { return "Pages / Views"; }
    if segment in ["api", "routes", "route", "endpoints"] { return "API Routes"; }
    if segment in ["controllers", "controller", "handlers"] { return "Controllers"; }
    if segment in ["services", "service"] { return "Services"; }
    if segment in ["agents", "agent"] { return "Agents"; }
    if segment in ["models", "model", "schema", "schemas", "types", "entities"] { return "Data Models"; }
    if segment in ["orchestration", "workflows", "workflow"] { return "Orchestration"; }
    if segment in ["hooks", "hook", "composables"] { return "Hooks"; }
    if segment in ["graph", "graphs"] { return "Graph Engine"; }
    if segment in ["memory", "store", "stores", "state"] { return "State / Memory"; }
    if segment in ["utils", "util", "helpers", "lib", "shared", "common"] { return "Utilities"; }
    if segment in ["config", "configs", "configuration", "settings"] { return "Configuration"; }
    if segment in ["tests", "test", "__tests__", "spec", "specs"] { return "Tests"; }
    if segment in ["styles", "style", "css", "assets", "public", "static"] { return "Styles / Assets"; }
    if segment in ["middleware", "middlewares"] { return "Middleware"; }
    if segment in ["migrations", "migration", "db", "database"] { return "Database"; }
    if segment in ["docs", "doc", "documentation"] { return "Documentation"; }
    if segment in ["src"] { return "Source"; }
    if segment in ["app"] { return "Application"; }
    return segment;
}

def dir_area_team(label: str) -> str {
    if label in ["UI Components", "Pages / Views", "Styles / Assets", "Hooks"] { return "Client Team"; }
    if label in ["API Routes", "Controllers", "Services", "Middleware", "Database"] { return "Backend Team"; }
    if label in ["Agents", "Orchestration", "Graph Engine", "State / Memory"] { return "Core Team"; }
    if label in ["Data Models", "Configuration"] { return "Core Team"; }
    if label in ["Tests"] { return "QA Team"; }
    if label in ["Documentation"] { return "All Teams"; }
    if label in ["Utilities", "Source", "Application"] { return "Core Team"; }
    return "Core Team";
}

def dir_area_confidence(label: str) -> float {
    if label in ["API Routes", "Controllers"] { return 0.80; }
    if label in ["Agents", "Orchestration"] { return 0.78; }
    if label in ["Services"] { return 0.76; }
    if label in ["Graph Engine", "Source"] { return 0.75; }
    if label in ["UI Components"] { return 0.74; }
    if label in ["Pages / Views"] { return 0.73; }
    if label in ["Data Models"] { return 0.72; }
    if label in ["Hooks"] { return 0.70; }
    if label in ["State / Memory", "Middleware", "Database"] { return 0.68; }
    if label in ["Configuration"] { return 0.65; }
    if label in ["Styles / Assets"] { return 0.60; }
    if label in ["Tests"] { return 0.58; }
    return 0.50;
}

def path_area_key(file_path: str) -> str {
    parts: list[str] = file_path.split("/");
    if len(parts) >= 3 {
        seg0: str = lower_text(parts[0]);
        seg1: str = lower_text(parts[1]);
        if seg0 in ["src", "app", "lib"] {
            label: str = dir_area_label(seg1);
            if label != seg1 {
                return seg0 + "/" + seg1;
            }
        }
    }
    if len(parts) >= 2 {
        seg: str = lower_text(parts[0]);
        label: str = dir_area_label(seg);
        if label != seg {
            return seg;
        }
    }
    return "";
}

def build_ownership(repo_summary_name: str, files: list[FileMatch]) -> list[OwnershipGuess] {
    ownership: list[OwnershipGuess] = [];
    seen_keys: list[str] = [];
    seen_labels: list[str] = [];

    for item in files {
        key: str = path_area_key(item.path);
        if not key or key in seen_keys {
            continue;
        }
        parts: list[str] = key.split("/");
        seg: str = parts[len(parts) - 1];
        label: str = dir_area_label(seg);
        if label in seen_labels {
            continue;
        }
        seen_keys.append(key);
        seen_labels.append(label);
        team: str = dir_area_team(label);
        conf: float = dir_area_confidence(label);
        ownership.append(
            OwnershipGuess(
                area=label,
                owner=team,
                confidence=conf,
                rationale="Inferred from files under " + key + "/ in " + repo_summary_name + "."
            )
        );
        if len(ownership) >= 5 {
            break;
        }
    }

    if len(ownership) == 0 and len(files) > 0 {
        ownership.append(
            OwnershipGuess(
                area="Project",
                owner="Core Team",
                confidence=0.50,
                rationale="Ownership inferred from top-level structure in " + repo_summary_name + "."
            )
        );
    }

    return ownership;
}

def to_planning_insight(title: str, detail: str, severity: str, category: str) -> PlanningInsight {
    return PlanningInsight(title=title, detail=detail, severity=severity, category=category);
}

def build_planning(
    request: WorkflowRequest,
    files: list[FileMatch],
    blockers: list[BlockerItem],
    graph: ProjectContextGraph,
    meeting_summary: MeetingSummary
) -> ExecutionPlanningContext {
    resolved_areas: list[str] = [];
    impacts: list[str] = [];
    test_gaps: list[str] = [];
    blocker_titles: list[str] = [];
    resolved_mappings: list[PlanningInsight] = [];
    blocker_insights: list[PlanningInsight] = [];
    impact_insights: list[PlanningInsight] = [];
    test_gap_insights: list[PlanningInsight] = [];

    resolved = resolve_context(request, files, graph);
    blocker_results = detect_blockers(request, meeting_summary, files, graph);
    impact_results = analyze_dependency_impact(request, files, graph);
    gap_results = identify_test_gaps(request, meeting_summary, files);

    for item in resolved {
        resolved_areas.append(item.target);
        resolved_mappings.append(to_planning_insight(item.target, item.rationale, "medium", "resolved"));
    }
    for item in impact_results {
        impacts.append(item.area + " — " + item.detail);
        impact_insights.append(to_planning_insight(item.area, item.detail, item.risk, "impact"));
    }
    for item in gap_results {
        test_gaps.append(item.area + " — " + item.recommendation);
        test_gap_insights.append(to_planning_insight(item.area, item.recommendation, item.risk, item.test_type));
    }
    for blocker in blockers {
        blocker_titles.append(blocker.title);
    }
    for item in blocker_results {
        if item.title not in blocker_titles {
            blocker_titles.append(item.title);
        }
        blocker_insights.append(to_planning_insight(item.title, item.detail, item.severity, item.impacted_area));
    }

    return ExecutionPlanningContext(
        resolved_areas=resolved_areas,
        impacts=impacts,
        test_gaps=test_gaps,
        blocker_titles=blocker_titles,
        resolved_mappings=resolved_mappings,
        blocker_insights=blocker_insights,
        impact_insights=impact_insights,
        test_gap_insights=test_gap_insights
    );
}

def build_bundle_summary(kind: str, repo_summary: RepoSummary, files: list[FileMatch], tasks: list[TaskItem], blockers: list[BlockerItem]) -> str {
    if kind == "context_preview" {
        return "Context preview ready for " + repo_summary.project_name + " with " + str(len(files)) + " grounded files.";
    }
    workstreams: int = len(tasks);
    if workstreams == 0 {
        workstreams = len(files);
    }
    blocker_text: str = "No blockers surfaced.";
    if len(blockers) == 1 {
        blocker_text = "1 blocker still needs follow-up.";
    } elif len(blockers) > 1 {
        blocker_text = str(len(blockers)) + " blockers still need follow-up.";
    }
    return repo_summary.project_name + " is organized around " + str(workstreams) + " next-step workstreams. " + blocker_text;
}

def object_value(source: any, key: str) -> any | None {
    if source is None {
        return None;
    }
    if type(source) == dict {
        if key in source {
            return source[key];
        }
        return None;
    }
    try {
        return getattr(source, key);
    } except AttributeError {
        return None;
    } except TypeError {
        return None;
    }
}

def object_text(source: any, key: str) -> str {
    value: any | None = object_value(source, key);
    if value is None {
        return "";
    }
    return str(value);
}

def object_items(source: any, key: str) -> list[any] {
    value: any | None = object_value(source, key);
    if type(value) == list {
        return cast(list[any], value);
    }
    return [];
}

def join_any_items(items: list[any], separator: str = ", ") -> str {
    text: str = "";
    for item in items {
        if text {
            text = text + separator;
        }
        text = text + str(item);
    }
    return text;
}

def artifact_context_text(bundle: any) -> str {
    lines: list[str] = [];
    run_state: any | None = object_value(bundle, "run_state");
    repo_summary: any | None = object_value(bundle, "repo_summary");
    meeting_summary: any | None = object_value(bundle, "meeting_summary");
    handoff: any | None = object_value(bundle, "handoff");
    standup: any | None = object_value(bundle, "standup");
    review: any | None = object_value(bundle, "review");

    if object_text(run_state, "summary") {
        lines.append("Run summary: " + object_text(run_state, "summary"));
    }
    if object_text(repo_summary, "project_name") or object_text(repo_summary, "overview") {
        lines.append("Project: " + object_text(repo_summary, "project_name") + " | " + object_text(repo_summary, "overview"));
    }
    if object_text(meeting_summary, "summary") {
        lines.append("Transcript summary: " + object_text(meeting_summary, "summary"));
    }
    for item in object_items(bundle, "decisions")[0:6] {
        lines.append("Decision: " + object_text(item, "title") + " | " + object_text(item, "detail"));
    }
    for item in object_items(bundle, "blockers")[0:6] {
        lines.append("Blocker: " + object_text(item, "title") + " | " + object_text(item, "detail"));
    }
    for item in object_items(bundle, "tasks")[0:6] {
        lines.append(
            "Task: " + object_text(item, "title")
            + " | " + object_text(item, "summary")
            + " | files=" + join_any_items(object_items(item, "likely_files"))
        );
    }
    for item in object_items(bundle, "tickets")[0:5] {
        lines.append("Ticket: " + object_text(item, "title") + " | " + object_text(item, "summary"));
    }
    if object_text(handoff, "summary") {
        lines.append("Handoff: " + object_text(handoff, "summary"));
    }
    for item in object_items(handoff, "next_actions")[0:4] {
        lines.append("Handoff next: " + str(item));
    }
    for item in object_items(standup, "done")[0:3] {
        lines.append("Standup done: " + str(item));
    }
    for item in object_items(standup, "next")[0:4] {
        lines.append("Standup next: " + str(item));
    }
    for item in object_items(review, "risk_hotspots")[0:5] {
        lines.append("Review hotspot: " + str(item));
    }
    for item in object_items(bundle, "relevant_files")[0:10] {
        lines.append("Relevant file: " + object_text(item, "path") + " | " + object_text(item, "rationale"));
    }
    for item in object_items(bundle, "trace")[0:10] {
        lines.append("Trace: " + object_text(item, "agent") + " | " + object_text(item, "detail"));
    }
    return join_lines(lines);
}

def deterministic_artifact_answer(prompt: str, bundle: any) -> str {
    answer_lines: list[str] = [];
    run_state: any | None = object_value(bundle, "run_state");
    meeting_summary: any | None = object_value(bundle, "meeting_summary");
    if object_text(run_state, "summary") {
        answer_lines.append(object_text(run_state, "summary"));
    }
    if object_text(meeting_summary, "summary") {
        answer_lines.append("Transcript: " + object_text(meeting_summary, "summary"));
    }
    bundle_tasks: list[any] = object_items(bundle, "tasks");
    if len(bundle_tasks) > 0 {
        answer_lines.append("Top task: " + object_text(bundle_tasks[0], "title") + " — " + object_text(bundle_tasks[0], "summary"));
    }
    bundle_tickets: list[any] = object_items(bundle, "tickets");
    if len(bundle_tickets) > 0 {
        answer_lines.append("Top ticket: " + object_text(bundle_tickets[0], "title") + " — " + object_text(bundle_tickets[0], "summary"));
    }
    bundle_blockers: list[any] = object_items(bundle, "blockers");
    if len(bundle_blockers) > 0 {
        answer_lines.append("Key blocker: " + object_text(bundle_blockers[0], "title") + " — " + object_text(bundle_blockers[0], "detail"));
    }
    if len(answer_lines) == 0 {
        answer_lines.append("No completed run artifacts are available yet.");
    }
    return "Answering from the current run for \"" + prompt + "\":\n" + join_lines(answer_lines);
}

def execute_workflow(request: WorkflowRequest, kind: str) -> WorkflowResultBundle {
    configure_request_llm(request.user_api_key, request.user_model);
    full_generation: bool = kind == "full_run";
    model_name: str = llm_model_name() if llm_available() else "";
    bundle: WorkflowResultBundle = WorkflowResultBundle();
    trace: list[WorkflowTraceStep] = [];
    content_cache: dict[str, str] = {};

    scanned_files: list[FileMatch] = scan_repo(request.repo_path);
    repo_summary: RepoSummary = run_repo_mapper(request.repo_path, scanned_files, content_cache);
    meeting_summary: MeetingSummary = run_meeting_interpreter(request.meeting_text);
    relevant_files: list[FileMatch] = run_code_search(request.repo_path, request.prompt, request.meeting_text, scanned_files);
    docs_result: DocsSyncResult = run_docs_sync(request.repo_path, content_cache);
    doc_files: list[FileMatch] = docs_result.files;
    doc_decisions: list[DecisionItem] = docs_result.decisions;

    repo_outcome: RepoSummaryOutcome = RepoSummaryOutcome(summary=repo_summary);
    meeting_outcome: MeetingSummaryOutcome = MeetingSummaryOutcome(summary=meeting_summary);
    code_search_outcome: FileMatchesOutcome = FileMatchesOutcome(files=relevant_files);
    docs_outcome: DecisionItemsOutcome = DecisionItemsOutcome(decisions=doc_decisions);

    repo_future: RepoSummaryOutcome | None = None;
    meeting_future: MeetingSummaryOutcome | None = None;
    code_search_future: FileMatchesOutcome | None = None;
    docs_future: DecisionItemsOutcome | None = None;

    if len(scanned_files) > 0 {
        if llm_available() {
            repo_future = enrich_repo_summary(request.repo_path, scanned_files, repo_summary);
        } else {
            repo_outcome.mode = "fallback";
            repo_outcome.reason = llm_unavailable_reason();
        }
    }
    if request.meeting_text {
        if llm_available() {
            meeting_future = enrich_meeting_summary(request.meeting_text, meeting_summary);
        } else {
            meeting_outcome.mode = "fallback";
            meeting_outcome.reason = llm_unavailable_reason();
        }
    }
    if llm_available() and len(relevant_files) > 0 and (request.prompt or request.meeting_text) {
        code_search_future = rerank_relevant_files(request.prompt, request.meeting_text, relevant_files);
    }
    if llm_available() and len(doc_files) > 0 {
        docs_future = enrich_doc_decisions(request.repo_path, doc_files, doc_decisions, content_cache);
    }

    if repo_future is not None {
        repo_outcome = cast(RepoSummaryOutcome, repo_future);
        repo_summary = repo_outcome.summary;
    }
    trace.append(
        trace_step(
            "stage_1",
            "Repo Mapper Agent",
            "Mapped repo structure for " + repo_summary.project_name + " across " + str(len(scanned_files)) + " scanned files.",
            repo_outcome.mode,
            repo_outcome.reason,
            model_name
        )
    );

    if meeting_future is not None {
        meeting_outcome = cast(MeetingSummaryOutcome, meeting_future);
        meeting_summary = meeting_outcome.summary;
    }
    trace.append(
        trace_step(
            "stage_1",
            "Meeting Interpreter Agent",
            "Parsed meeting context: " + meeting_summary.summary,
            meeting_outcome.mode,
            meeting_outcome.reason,
            model_name
        )
    );

    if code_search_future is not None {
        code_search_outcome = cast(FileMatchesOutcome, code_search_future);
        relevant_files = code_search_outcome.files;
    }
    trace.append(
        trace_step(
            "stage_1",
            "Code Search Agent",
            "Ranked " + str(len(relevant_files)) + " relevant files from deterministic repo search.",
            code_search_outcome.mode,
            code_search_outcome.reason,
            model_name
        )
    );

    if docs_future is not None {
        docs_outcome = cast(DecisionItemsOutcome, docs_future);
        doc_decisions = docs_outcome.decisions;
    }
    trace.append(
        trace_step(
            "stage_1",
            "Docs Sync Agent",
            "Pulled " + str(len(doc_files)) + " documentation files into project context.",
            docs_outcome.mode,
            docs_outcome.reason,
            model_name
        )
    );

    merged_files: list[FileMatch] = relevant_files + doc_files;
    merged_decisions: list[DecisionItem] = meeting_summary.decisions + doc_decisions;
    merged_blockers: list[BlockerItem] = meeting_summary.blockers;

    ownership: list[OwnershipGuess] = build_ownership(repo_summary.project_name, merged_files);
    planning_seed: ExecutionPlanningContext = ExecutionPlanningContext();
    graph_seed: ProjectContextGraph = build_stage_one_seed_graph(
        request,
        repo_summary,
        meeting_summary,
        merged_files,
        merged_decisions,
        merged_blockers,
        ownership,
        planning_seed,
        trace
    );
    trace.append(
        trace_step(
            "stage_1_merge",
            "Context Graph Builder",
            "Merged stage 1 outputs into the unified project context graph.",
            "deterministic"
        )
    );

    planning: ExecutionPlanningContext = build_planning(request, merged_files, merged_blockers, graph_seed, meeting_summary);
    trace.append(
        trace_step(
            "stage_2",
            "Context Resolver Agent",
            "Resolved vague request language to " + str(len(planning.resolved_areas)) + " concrete files or graph focus paths.",
            "deterministic"
        )
    );
    trace.append(
        trace_step(
            "stage_2",
            "Blocker Detector Agent",
            "Surfaced " + str(len(planning.blocker_titles)) + " blocker and dependency signals.",
            "deterministic"
        )
    );
    trace.append(
        trace_step(
            "stage_2",
            "Dependency Impact Agent",
            "Predicted downstream impact across " + str(len(planning.impacts)) + " likely change surfaces.",
            "deterministic"
        )
    );
    trace.append(
        trace_step(
            "stage_2",
            "Test Gap Agent",
            "Suggested " + str(len(planning.test_gaps)) + " coverage targets for risky paths.",
            "deterministic"
        )
    );
    trace.append(
        trace_step(
            "stage_2_merge",
            "Planning Context Merger",
            "Merged Stage 2 reasoning into the execution planning context.",
            "deterministic"
        )
    );

    action_plan: ActionPlan = build_action_plan(request, planning, merged_files);
    action_plan_mode: str = "deterministic";
    action_plan_reason: str = "";
    tasks: list[TaskItem] = build_action_tasks(request, planning, merged_files, meeting_summary);
    tasks_mode: str = "deterministic";
    tasks_reason: str = "";
    action_plan_future: ActionPlanOutcome | None = None;
    tasks_future: TasksOutcome | None = None;
    if full_generation {
        if llm_available() {
            action_plan_future = enrich_action_plan(request, planning, merged_files, action_plan);
            tasks_future = enrich_action_tasks(request, planning, merged_files, meeting_summary, tasks);
        } else {
            action_plan_mode = "fallback";
            action_plan_reason = llm_unavailable_reason();
            tasks_mode = "fallback";
            tasks_reason = llm_unavailable_reason();
        }
    }

    if action_plan_future is not None {
        action_plan_outcome: ActionPlanOutcome = cast(ActionPlanOutcome, action_plan_future);
        action_plan = action_plan_outcome.plan;
        action_plan_mode = action_plan_outcome.mode;
        action_plan_reason = action_plan_outcome.reason;
    }
    trace.append(
        trace_step(
            "stage_3",
            "Action Planner Agent",
            "Prepared the action plan and staged execution order.",
            action_plan_mode,
            action_plan_reason,
            model_name
        )
    );

    if tasks_future is not None {
        tasks_outcome: TasksOutcome = cast(TasksOutcome, tasks_future);
        tasks = tasks_outcome.tasks;
        tasks_mode = tasks_outcome.mode;
        tasks_reason = tasks_outcome.reason;
    }

    tickets: list[GeneratedTicket] = write_tickets(request, planning, tasks, merged_files);
    tickets_mode: str = "deterministic";
    tickets_reason: str = "";
    tickets_future: TicketsOutcome | None = None;
    handoff: HandoffNoteData = generate_handoff(request, planning, tasks, merged_files);
    handoff_mode: str = "deterministic";
    handoff_reason: str = "";
    handoff_future: HandoffOutcome | None = None;
    review: ReviewScopeData = prepare_review_scope(request, planning, tasks, merged_files);
    review_mode: str = "deterministic";
    review_reason: str = "";
    review_future: ReviewOutcome | None = None;
    if full_generation {
        if llm_available() {
            tickets_future = enrich_tickets(request, planning, tasks, merged_files, tickets);
            handoff_future = enrich_handoff(request, planning, tasks, merged_files, handoff);
            review_future = enrich_review_scope(request, planning, tasks, merged_files, review);
        } else {
            tickets_mode = "fallback";
            tickets_reason = llm_unavailable_reason();
            handoff_mode = "fallback";
            handoff_reason = llm_unavailable_reason();
            review_mode = "fallback";
            review_reason = llm_unavailable_reason();
        }
    }

    if tickets_future is not None {
        tickets_outcome: TicketsOutcome = cast(TicketsOutcome, tickets_future);
        tickets = tickets_outcome.tickets;
        tickets_mode = tickets_outcome.mode;
        tickets_reason = tickets_outcome.reason;
    }
    trace.append(
        trace_step(
            "stage_3",
            "Ticket Writer Agent",
            "Created " + str(len(tickets)) + " ticket-ready execution items.",
            tickets_mode,
            tickets_reason,
            model_name
        )
    );

    standup: StandupUpdateData = generate_standup(request, planning, tasks, trace, meeting_summary);
    standup_mode: str = "deterministic";
    standup_reason: str = "";
    standup_future: StandupOutcome | None = None;
    if full_generation {
        if llm_available() {
            standup_future = enrich_standup(request, planning, tasks, trace, meeting_summary, standup);
        } else {
            standup_mode = "fallback";
            standup_reason = llm_unavailable_reason();
        }
    }

    if standup_future is not None {
        standup_outcome: StandupOutcome = cast(StandupOutcome, standup_future);
        standup = standup_outcome.standup;
        standup_mode = standup_outcome.mode;
        standup_reason = standup_outcome.reason;
    }
    trace.append(
        trace_step(
            "stage_3",
            "Standup Agent",
            "Prepared the standup update with done, next, and blocker sections.",
            standup_mode,
            standup_reason,
            model_name
        )
    );

    if handoff_future is not None {
        handoff_outcome: HandoffOutcome = cast(HandoffOutcome, handoff_future);
        handoff = handoff_outcome.handoff;
        handoff_mode = handoff_outcome.mode;
        handoff_reason = handoff_outcome.reason;
    }
    trace.append(
        trace_step(
            "stage_3",
            "Handoff Agent",
            "Prepared next-developer handoff notes with risks and next actions.",
            handoff_mode,
            handoff_reason,
            model_name
        )
    );

    if review_future is not None {
        review_outcome: ReviewOutcome = cast(ReviewOutcome, review_future);
        review = review_outcome.review;
        review_mode = review_outcome.mode;
        review_reason = review_outcome.reason;
    }
    trace.append(
        trace_step(
            "stage_3",
            "PR Review Prep Agent",
            "Prepared review scope, hotspots, and reviewer checklist.",
            review_mode,
            review_reason,
            model_name
        )
    );

    trace.append(
        trace_step(
            "stage_3_merge",
            "Output Bundle Merger",
            "Merged Stage 3 artifacts into the structured workflow bundle.",
            "deterministic"
        )
    );

    bundle.repo_summary = repo_summary;
    bundle.meeting_summary = meeting_summary;
    bundle.relevant_files = merged_files;
    bundle.ownership = ownership;
    bundle.decisions = merged_decisions;
    bundle.blockers = merged_blockers;
    bundle.planning = planning;
    bundle.action_plan = action_plan;
    bundle.tasks = tasks;
    bundle.tickets = tickets;
    bundle.standup = standup;
    bundle.handoff = handoff;
    bundle.review = review;

    if full_generation {
        remember_session(request, bundle);
        memory_snapshot: dict = update_project_memory(request.repo_path, bundle);
        updated_at = str(memory_snapshot["updated_at"]);
        bundle.review.checklist = bundle.review.checklist + ["Memory updated at " + updated_at];
        trace.append(
            trace_step(
                "stage_3_merge",
                "Decision Memory Agent",
                "Updated session and project memory for the completed full run.",
                "deterministic"
            )
        );
    }

    bundle.trace = trace;
    bundle.context_graph = finalize_context_graph(graph_seed, tasks, tickets, handoff, standup, review, trace);
    bundle.run_state = make_run_state(
        request,
        kind,
        build_bundle_summary(kind, repo_summary, merged_files, tasks, merged_blockers),
        trace
    );
    return bundle;
}

def:pub preview_context(repo_path: str, meeting_text: str, mode: str = "feature_plan", user_api_key: str = "", user_model: str = "") -> WorkflowResultBundle {
    request: WorkflowRequest = WorkflowRequest(
        repo_path=repo_path,
        meeting_text=meeting_text,
        prompt="",
        mode=mode,
        user_api_key=user_api_key,
        user_model=user_model
    );
    return execute_workflow(request, "context_preview");
}

def:pub run_workflow(repo_path: str, meeting_text: str, prompt: str, mode: str = "feature_plan", user_api_key: str = "", user_model: str = "") -> WorkflowResultBundle {
    request: WorkflowRequest = WorkflowRequest(
        repo_path=repo_path,
        meeting_text=meeting_text,
        prompt=prompt,
        mode=mode,
        user_api_key=user_api_key,
        user_model=user_model
    );
    return execute_workflow(request, "full_run");
}

def:pub get_memory_snapshot(repo_path: str) -> dict {
    return get_project_memory(repo_path);
}

def:pub query_run_artifacts(prompt: str, bundle: str, user_api_key: str = "", user_model: str = "") -> str {
    if not prompt {
        return "Add a follow-up question after the run completes.";
    }
    bundle_data: any = {};
    try {
        bundle_data = json.loads(bundle) if bundle else {};
    } except Exception {
        bundle_data = {};
    }
    try {
        configure_request_llm(user_api_key, user_model);
        artifact_context: str = slice_text(artifact_context_text(bundle_data), 12000);
        if llm_available() {
            try {
                qa: QueryArtifactAnswer = llm_query_run_artifacts(slice_text(prompt, 1200), artifact_context);
                return json.dumps({
                    "answer": qa.answer,
                    "key_points": qa.key_points,
                    "relevant_files": qa.relevant_files,
                    "blockers": qa.blockers,
                    "next_steps": qa.next_steps
                });
            } except ByLLMError {
                return deterministic_artifact_answer(prompt, bundle_data);
            } except RuntimeError {
                return deterministic_artifact_answer(prompt, bundle_data);
            } except ValueError {
                return deterministic_artifact_answer(prompt, bundle_data);
            } except TypeError {
                return deterministic_artifact_answer(prompt, bundle_data);
            } except OSError {
                return deterministic_artifact_answer(prompt, bundle_data);
            } except Exception {
                return deterministic_artifact_answer(prompt, bundle_data);
            }
        }
        return deterministic_artifact_answer(prompt, bundle_data);
    } except Exception {
        return deterministic_artifact_answer(prompt, bundle_data);
    }
}
