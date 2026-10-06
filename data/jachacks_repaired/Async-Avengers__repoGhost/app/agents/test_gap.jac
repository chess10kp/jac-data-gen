import from app.models.core { FileMatch, MeetingSummary }
import from app.models.workflow { WorkflowRequest }

obj TestGapInsight {
    has area: str = "";
    has recommendation: str = "";
    has test_type: str = "unit";
    has risk: str = "medium";
}

def gap_test_type(path: str) -> str {
    if path.startswith("app/orchestration") or path.startswith("app/services") {
        return "integration";
    }
    if path.startswith("app/components") or path.startswith("app/hooks") {
        return "e2e";
    }
    return "unit";
}

def:pub identify_test_gaps(request: WorkflowRequest, meeting: MeetingSummary, files: list[FileMatch]) -> list[TestGapInsight] {
    gaps: list[TestGapInsight] = [];
    for item in files[:6] {
        item_test_type: str = gap_test_type(item.path);
        gaps.append(TestGapInsight(
            area=item.path,
            recommendation="Add " + item_test_type + " coverage for the request path touching " + item.path + ".",
            test_type=item_test_type,
            risk=("high" if item.score > 0.8 else "medium")
        ));
    }
    if len(meeting.action_items) > 2 {
        gaps.append(TestGapInsight(area="meeting parsing", recommendation="Add parser coverage for multi-action meeting notes, deadlines, and uncertainty extraction.", test_type="unit", risk="medium"));
    }
    if request.mode in ["handoff", "standup", "review_prep"] {
        gaps.append(TestGapInsight(area="artifact generation", recommendation="Add integration coverage for mode-specific output shaping and fallback behavior.", test_type="integration", risk="medium"));
    }
    return gaps;
}
