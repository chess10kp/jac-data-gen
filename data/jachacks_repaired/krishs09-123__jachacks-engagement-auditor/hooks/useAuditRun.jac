import from ..services.audits {
    start_audit,
    get_audit_run,
    list_engagement_findings,
    export_report,
}
import from ..services.models {
    AuditMutationResult,
    AuditRunView,
    EngagementFinding,
    ExportReport,
}

obj AuditRunState {
    has view: AuditRunView | None = None;
    has engagementFindings: list[EngagementFinding] = [];
    has loading: bool = False;
    has error: str = "";
    has exported: ExportReport | None = None;
    has refresh: any = None;
    has exportReport: any = None;
}

obj StartAuditState {
    has running: bool = False;
    has error: str = "";
    has start: any = None;
}

def:pub useAuditRun(audit_id: str) -> AuditRunState {
    has view: AuditRunView | None = None;
    has engagementFindings: list[EngagementFinding] = [];
    has loading: bool = False;
    has error: str = "";
    has exported: ExportReport | None = None;

    async def refresh() -> None {
        if len(audit_id) == 0 {
            return;
        }
        loading = True;
        error = "";
        try {
            loaded_view: AuditRunView | None = None;
            loaded_view = await get_audit_run(audit_id);
            view = loaded_view;
            if loaded_view is not None and not loaded_view.ok {
                error = loaded_view.message;
            }
            loaded_engagement: list[EngagementFinding] = [];
            loaded_engagement = await list_engagement_findings(audit_id);
            engagementFindings = loaded_engagement;
        } except Exception as e {
            error = f"Could not load audit: {e}";
        }
        loading = False;
    }

    async def exportReport() -> ExportReport | None {
        try {
            export_result: ExportReport | None = None;
            export_result = await export_report(audit_id);
            exported = export_result;
            return export_result;
        } except Exception as e {
            error = f"Could not export report: {e}";
        }
        return None;
    }

    async can with entry {
        await refresh();
    }

    return AuditRunState(
        view=view,
        engagementFindings=engagementFindings,
        loading=loading,
        error=error,
        exported=exported,
        refresh=refresh,
        exportReport=exportReport,
    );
}

def:pub useStartAudit() -> StartAuditState {
    has running: bool = False;
    has error: str = "";

    async def start(project_id: str, url: str) -> AuditMutationResult | None {
        running = True;
        error = "";
        try {
            response: AuditMutationResult | None = None;
            response = await start_audit(project_id, url);
            if response is not None and not response.ok {
                error = response.message;
            }
            running = False;
            return response;
        } except Exception as e {
            error = f"Could not start audit: {e}";
        }
        running = False;
        return None;
    }

    return StartAuditState(
        running=running,
        error=error,
        start=start,
    );
}
