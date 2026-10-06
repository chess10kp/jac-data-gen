import from app.models.core { FileMatch }
import from app.models.workflow { WorkflowRequest }
import from app.models.outputs { ProjectContextGraph }

obj ImpactInsight {
    has area: str = "";
    has detail: str = "";
    has risk: str = "medium";
}

def last_path_part(text: str) -> str {
    parts: list[str] = text.split("/");
    if len(parts) > 0 {
        return parts[len(parts) - 1];
    }
    return text;
}

def impact_risk(path: str) -> str {
    lower: str = path.lower();
    high_patterns: list[str] = ["/orchestration/", "/workflow", "/graph/", "/services/", "/api/", "/routes/", "/agents/"];
    for pattern in high_patterns {
        if pattern in ("/" + lower) {
            return "high";
        }
    }
    mid_patterns: list[str] = ["/components/", "/views/", "/pages/", "/controllers/", "/models/", "/schema/"];
    for pattern in mid_patterns {
        if pattern in ("/" + lower) {
            return "medium";
        }
    }
    entry_names: list[str] = ["main.py", "main.ts", "main.js", "app.py", "manage.py", "wsgi.py", "asgi.py", "server.py", "index.ts", "index.js"];
    filename: str = last_path_part(lower);
    if filename in entry_names {
        return "medium";
    }
    return "low";
}

def:pub analyze_dependency_impact(request: WorkflowRequest, files: list[FileMatch], graph: ProjectContextGraph) -> list[ImpactInsight] {
    impacts: list[ImpactInsight] = [];
    for item in files[:6] {
        detail = "Changes touching " + item.path + " likely ripple into workflow orchestration, UI panels, or graph-backed outputs.";
        impacts.append(ImpactInsight(area=item.path, detail=detail, risk=impact_risk(item.path)));
    }
    if len(graph.edges) > 12 {
        impacts.append(ImpactInsight(area="context graph relationships", detail="Dense graph relationships suggest downstream updates across blockers, tickets, and review scope views.", risk="high"));
    }
    if request.mode == "review_prep" {
        impacts.append(ImpactInsight(area="review workflow", detail="Review prep mode should validate changed areas, risk hotspots, and reviewer checklist generation together.", risk="medium"));
    }
    return impacts;
}
