import from app.models.core { BlockerItem, MeetingSummary, FileMatch }
import from app.models.workflow { WorkflowRequest }
import from app.models.outputs { ProjectContextGraph }

obj BlockerInsight {
    has title: str = "";
    has detail: str = "";
    has severity: str = "medium";
    has impacted_area: str = "";
}

def:pub detect_blockers(request: WorkflowRequest, meeting: MeetingSummary, files: list[FileMatch], graph: ProjectContextGraph) -> list[BlockerInsight] {
    insights: list[BlockerInsight] = [];
    blockers = meeting.blockers if meeting and meeting.blockers else [];
    ranked_files = files or [];
    focus_paths = graph.focus_paths if graph and graph.focus_paths else [];
    repo_path = request.repo_path.strip() if request and request.repo_path else "";
    meeting_text = request.meeting_text.lower() if request and request.meeting_text else "";

    if len(blockers) > 0 {
        for item in blockers[:5] {
            insights.append(BlockerInsight(title=item.title, detail=item.detail, severity=item.severity, impacted_area="meeting context"));
        }
    }
    if not repo_path {
        insights.append(BlockerInsight(title="Missing permitted repo path", detail="RepoGhost cannot ground reasoning without a selected local repository.", severity="high", impacted_area="repo ingestion"));
    }
    if len(ranked_files) == 0 {
        insights.append(BlockerInsight(title="Low code grounding", detail="No relevant files were ranked for the current request, so downstream planning confidence is reduced.", severity="high", impacted_area="code search"));
    }
    if len(focus_paths) < 2 {
        insights.append(BlockerInsight(title="Thin context graph", detail="The unified project context graph has too few focus paths to support confident execution planning.", severity="medium", impacted_area="context graph"));
    }
    if "api" in meeting_text and "contract" not in meeting_text {
        insights.append(BlockerInsight(title="Missing API contract detail", detail="Meeting context references API work without a clear contract, schema, or payload definition.", severity="medium", impacted_area="integration design"));
    }
    return insights;
}
