import from app.models.core { FileMatch, OwnershipGuess, MeetingSummary, DecisionItem, BlockerItem }
import from app.models.outputs {
    RepoSummary, TaskItem, ActionPlan, GeneratedTicket,
    HandoffNoteData, StandupUpdateData, ReviewScopeData, WorkflowResultBundle
}
import from app.models.workflow { ExecutionPlanningContext }
import from app.orchestration.trace { seed_trace }

def:pub get_demo_bundle() -> WorkflowResultBundle {
    return WorkflowResultBundle(
        repo_summary=RepoSummary(
            project_name="RepoGhost",
            overview="Desktop-ready AI developer sidecar that turns repo and meeting context into engineering execution.",
            frameworks=["Jac", "jac-client", "Tailwind"],
            entry_points=["main.jac", "app/orchestration/workflow.sv.jac"],
            major_dirs=["app/agents", "app/graph", "app/services", "app/components"]
        ),
        meeting_summary=MeetingSummary(
            summary="Team aligned on shipping a visible multi-agent workflow with repo-aware outputs for demo day.",
            action_items=["Wire repo ingestion", "Generate ticket-ready tasks", "Show agent timeline in UI"],
            decisions=[DecisionItem(title="Graph-first context", detail="Use Jac graph as the merged project context substrate.", confidence=0.92, source="meeting")],
            blockers=[BlockerItem(title="Repo permissions", detail="Need a permitted local path for indexing.", severity="medium", owner_hint="developer")],
            people=["Alex", "Priya"],
            systems=["desktop widget", "workflow orchestrator", "project memory"],
            deadlines=["Hackathon demo Friday"],
            uncertainty=["Ownership inference confidence depends on repo metadata."]
        ),
        relevant_files=[
            FileMatch(path="main.jac", score=0.98, rationale="Entry point for fullstack app and endpoint registration.", kind="entry"),
            FileMatch(path="app/orchestration/workflow.sv.jac", score=0.95, rationale="Coordinates staged multi-agent execution.", kind="service"),
            FileMatch(path="app/services/repo_ingest.sv.jac", score=0.91, rationale="Handles repo scanning and indexing.", kind="service")
        ],
        ownership=[
            OwnershipGuess(area="orchestration", owner="Platform Team", confidence=0.74, rationale="Core workflow modules cluster under orchestration."),
            OwnershipGuess(area="desktop shell", owner="Frontend Team", confidence=0.68, rationale="UI shell and widget components live together.")
        ],
        decisions=[DecisionItem(title="Visible agent trace", detail="Judges should see staged agents run and merge outputs.", confidence=0.95, source="product brief")],
        blockers=[BlockerItem(title="Semantic indexing deferred", detail="Hybrid ranking ships first with clean extension points for embeddings later.", severity="low", owner_hint="search")],
        planning=ExecutionPlanningContext(
            resolved_areas=["repo ingestion", "meeting parsing", "workflow orchestration", "workspace panels"],
            impacts=["UI state", "persistent memory", "search ranking", "trace rendering"],
            test_gaps=["Repo ignore rules", "workflow error handling", "desktop widget resizing"],
            blocker_titles=["Repo permissions", "Semantic indexing deferred"]
        ),
        action_plan=ActionPlan(
            headline="Build breadth-first, then deepen each stage with real data and byLLM reasoning.",
            first_task="Implement repo scan and meeting parse services.",
            next_task="Merge stage 1 outputs into the project context graph.",
            phases=["Ingest", "Resolve", "Plan", "Render"]
        ),
        tasks=[
            TaskItem(title="Scan repo and summarize modules", summary="Collect file metadata, entry points, and docs.", phase="Ingest", dependencies=["repo path"], likely_files=["app/services/repo_ingest.sv.jac"]),
            TaskItem(title="Interpret meeting transcript", summary="Extract tasks, blockers, decisions, and systems.", phase="Ingest", dependencies=["meeting text"], likely_files=["app/services/meeting_parse.sv.jac"]),
            TaskItem(title="Render structured outputs", summary="Show tickets, blockers, handoff, and review panes.", phase="Render", dependencies=["workflow bundle"], likely_files=["app/components/WorkspaceShell.cl.jac"])
        ],
        tickets=[
            GeneratedTicket(title="Implement staged workflow orchestrator", summary="Coordinate stage 1, 2, and 3 agents with visible trace.", priority="high", acceptance_criteria=["Stage 1 runs in parallel", "Trace is visible in UI", "Merged bundle persists to session memory"], likely_files=["app/orchestration/workflow.sv.jac", "app/orchestration/trace.sv.jac"], blockers=["Repo permissions"], dependencies=["repo ingestion", "meeting parsing"])
        ],
        handoff=HandoffNoteData(summary="RepoGhost shell is in place with typed contracts and seeded workflow outputs.", touched_areas=["models", "graph", "services", "UI shell"], risks=["Need syntax validation across all modules", "Desktop packaging config still pending"], next_actions=["Implement real repo ingestion", "Persist project memory", "Wire client hooks to workflow endpoint"]),
        standup=StandupUpdateData(done=["Defined architecture and graph contracts", "Built dark UI shell"], next=["Implement stage 1 services", "Wire hooks to backend endpoints"], blockers=["Need permitted repo path for live indexing"]),
        review=ReviewScopeData(summary="Review the staged orchestration contract and graph-native data flow.", changed_areas=["main entry", "models", "graph", "UI shell"], risk_hotspots=["Jac syntax drift", "client/server import boundaries"], checklist=["Endpoints imported in main.jac", "Hooks use sv import", "UI renders seeded bundle cleanly"]),
        trace=seed_trace()
    );
}
