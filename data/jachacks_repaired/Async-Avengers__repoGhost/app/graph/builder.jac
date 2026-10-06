import from app.models.core { FileMatch, MeetingSummary, DecisionItem, BlockerItem, OwnershipGuess }
import from app.models.workflow { WorkflowRequest, WorkflowTraceStep, ExecutionPlanningContext }
import from app.models.outputs {
    RepoSummary, TaskItem, GeneratedTicket, HandoffNoteData,
    StandupUpdateData, ReviewScopeData, GraphNodeView,
    GraphEdgeView, ProjectContextGraph
}

obj GraphBuildRefs {
    has project_ref: str = "project";
    has meeting_ref: str = "meeting";
    has request_ref: str = "request";
    has run_ref: str = "run";
    has result_ref: str = "result";
}

def add_node(nodes: list[GraphNodeView], node_id: str, kind: str, label: str, detail: str = "", group: str = "context") -> list[GraphNodeView] {
    nodes.append(GraphNodeView(id=node_id, kind=kind, label=label, detail=detail, group=group));
    return nodes;
}

def add_edge(edges: list[GraphEdgeView], source: str, target: str, kind: str, detail: str = "") -> list[GraphEdgeView] {
    edges.append(GraphEdgeView(source=source, target=target, kind=kind, detail=detail));
    return edges;
}

def build_graph_refs(request: WorkflowRequest) -> GraphBuildRefs {
    run_id = "run-" + request.mode;
    return GraphBuildRefs(
        project_ref="project-root",
        meeting_ref="meeting-current",
        request_ref="request-current",
        run_ref=run_id,
        result_ref=run_id + "-bundle"
    );
}

def refresh_trace_summary(graph: ProjectContextGraph, trace: list[WorkflowTraceStep]) -> ProjectContextGraph {
    graph.trace_summary = [];
    for step in trace {
        graph.trace_summary.append(step.agent + " • " + step.status);
    }
    return graph;
}

def:pub build_stage_one_seed_graph(
    request: WorkflowRequest,
    repo_summary: RepoSummary,
    meeting_summary: MeetingSummary,
    relevant_files: list[FileMatch],
    decisions: list[DecisionItem],
    blockers: list[BlockerItem],
    ownership: list[OwnershipGuess],
    planning: ExecutionPlanningContext,
    trace: list[WorkflowTraceStep]
) -> ProjectContextGraph {
    refs = build_graph_refs(request);
    nodes: list[GraphNodeView] = [];
    edges: list[GraphEdgeView] = [];
    focus_paths: list[str] = [];
    trace_summary: list[str] = [];

    add_node(nodes, refs.project_ref, "Project", repo_summary.project_name, repo_summary.overview, "project");
    add_node(nodes, refs.meeting_ref, "Meeting", "Current meeting", meeting_summary.summary, "meeting");
    add_node(nodes, refs.request_ref, "Request", request.mode, request.prompt, "request");
    add_node(nodes, refs.run_ref, "WorkflowRun", "Stage 1 merged", "Repo, meeting, docs, search, and memory merged into one context.", "workflow");
    add_node(nodes, refs.result_ref, "ResultBundle", "Unified context bundle", "Graph-backed context ready for UI rendering.", "result");

    add_edge(edges, refs.project_ref, refs.meeting_ref, "contains", "Project context includes the current meeting.");
    add_edge(edges, refs.project_ref, refs.request_ref, "contains", "Project context includes the current request.");
    add_edge(edges, refs.project_ref, refs.run_ref, "contains", "Workflow run belongs to the project.");
    add_edge(edges, refs.run_ref, refs.result_ref, "generated_from", "Run produced the current result bundle.");
    add_edge(edges, refs.request_ref, refs.run_ref, "next_for", "Request triggered the workflow run.");
    add_edge(edges, refs.meeting_ref, refs.result_ref, "derived_from", "Meeting meaning contributes to the merged context.");

    add_node(nodes, "repo-summary", "RepoSummary", repo_summary.project_name, repo_summary.overview, "summary");
    add_edge(edges, refs.project_ref, "repo-summary", "summarized_into", "Repo scan summarized the project.");

    for (index, item) in enumerate(relevant_files[:8]) {
        file_id = "file-" + str(index);
        add_node(nodes, file_id, "File", item.path, item.rationale, "files");
        add_edge(edges, refs.project_ref, file_id, "contains", item.kind);
        add_edge(edges, refs.request_ref, file_id, "resolved_to", "Score " + str(item.score));
        focus_paths.append(item.path);
    }

    for (index, item) in enumerate(decisions[:6]) {
        decision_id = "decision-" + str(index);
        add_node(nodes, decision_id, "Decision", item.title, item.detail, "memory");
        add_edge(edges, refs.meeting_ref, decision_id, "decided_in", "Decision extracted from meeting or docs.");
        add_edge(edges, refs.result_ref, decision_id, "surfaced_in", "Decision shown in current result bundle.");
    }

    for (index, item) in enumerate(blockers[:6]) {
        blocker_id = "blocker-" + str(index);
        add_node(nodes, blocker_id, "Blocker", item.title, item.detail, "blockers");
        add_edge(edges, refs.run_ref, blocker_id, "blocks", item.severity);
        add_edge(edges, refs.result_ref, blocker_id, "surfaced_in", "Blocker visible in workflow outputs.");
    }

    for (index, item) in enumerate(ownership[:4]) {
        owner_id = "owner-" + str(index);
        add_node(nodes, owner_id, "Person", item.owner, item.rationale, "ownership");
        add_edge(edges, refs.project_ref, owner_id, "owned_by", item.area + " • " + str(item.confidence));
    }

    add_node(nodes, "planning-context", "PlanningContext", "Execution planning", ", ".join(planning.impacts), "planning");
    add_edge(edges, refs.run_ref, "planning-context", "relates_to", "Stage 1 outputs prepared the planning context.");

    for step in trace {
        trace_summary.append(step.agent + " • " + step.status);
    }

    return ProjectContextGraph(
        project_id=refs.project_ref,
        run_id=refs.run_ref,
        nodes=nodes,
        edges=edges,
        focus_paths=focus_paths,
        trace_summary=trace_summary
    );
}

def:pub finalize_context_graph(
    graph: ProjectContextGraph,
    tasks: list[TaskItem],
    tickets: list[GeneratedTicket],
    handoff: HandoffNoteData,
    standup: StandupUpdateData,
    review: ReviewScopeData,
    trace: list[WorkflowTraceStep]
) -> ProjectContextGraph {
    result_ref: str = graph.run_id + "-bundle";

    for (index, item) in enumerate(tasks[:5]) {
        task_id = "task-" + str(index);
        add_node(graph.nodes, task_id, "Task", item.title, item.summary, "tasks");
        add_edge(graph.edges, result_ref, task_id, "contains", item.phase);
    }

    for (index, item) in enumerate(tickets[:4]) {
        ticket_id = "ticket-" + str(index);
        add_node(graph.nodes, ticket_id, "Ticket", item.title, item.summary, "tickets");
        add_edge(graph.edges, result_ref, ticket_id, "generated_from", item.priority);
    }

    add_node(graph.nodes, "handoff-note", "HandoffNote", "Handoff", handoff.summary, "outputs");
    add_node(graph.nodes, "standup-update", "StandupUpdate", "Standup", ", ".join(standup.next), "outputs");
    add_node(graph.nodes, "review-scope", "ReviewScope", "Review", review.summary, "outputs");
    add_edge(graph.edges, result_ref, "handoff-note", "contains", "handoff");
    add_edge(graph.edges, result_ref, "standup-update", "contains", "standup");
    add_edge(graph.edges, result_ref, "review-scope", "contains", "review");

    return refresh_trace_summary(graph, trace);
}

def:pub build_stage_one_graph(
    request: WorkflowRequest,
    repo_summary: RepoSummary,
    meeting_summary: MeetingSummary,
    relevant_files: list[FileMatch],
    decisions: list[DecisionItem],
    blockers: list[BlockerItem],
    ownership: list[OwnershipGuess],
    planning: ExecutionPlanningContext,
    tasks: list[TaskItem],
    tickets: list[GeneratedTicket],
    handoff: HandoffNoteData,
    standup: StandupUpdateData,
    review: ReviewScopeData,
    trace: list[WorkflowTraceStep]
) -> ProjectContextGraph {
    graph: ProjectContextGraph = build_stage_one_seed_graph(
        request,
        repo_summary,
        meeting_summary,
        relevant_files,
        decisions,
        blockers,
        ownership,
        planning,
        trace
    );
    return finalize_context_graph(graph, tasks, tickets, handoff, standup, review, trace);
}
