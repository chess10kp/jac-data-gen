import from "@jac/runtime" { Link as RuntimeLink, useParams as runtimeUseParams }
import from ..hooks.useAuditRun { useAuditRun }
import from ..components.AppShell { AppShell }
import from ..components.FindingList { FindingList, FindingListItem }
import from ..components.ui.Card { Card, CardContent, CardDescription, CardHeader, CardTitle }
import from ..components.ui.Progress { Progress }
import from ..components.ui.Alert { Alert }

async def:pub RetentionReportPage() -> JsxElement {
    params = runtimeUseParams();
    audit_id: str = str(params["id"]);
    auditState = await useAuditRun(audit_id);
    view = auditState.view;
    has_run: bool = False;
    retention_score: int = 0;
    display_findings: list[FindingListItem] = auditState.engagementFindings; # jac:ignore[E1001]
    if view is not None and view.run is not None {
        has_run = True;
        retention_score = view.run.retention_score;
    }

    return <AppShell auditId={audit_id}>
        <header className="page-header">
            <div>
                <p className="eyebrow">Retention report</p>
                <h1>Behavior loop findings</h1>
                <p className="page-subtitle">Plain-English retention science: cues, actions, rewards, learning loops, notifications, streak pressure, social validation, FoMO, and dark-pattern risk.</p>
            </div>
            <RuntimeLink className="table-link" to={"/audits/" + audit_id}>Audit overview</RuntimeLink>
        </header>

        {auditState.error != "" and <Alert tone="danger">{auditState.error}</Alert>}
        {has_run and <Card>
                <CardHeader>
                <CardTitle>Retention loop score</CardTitle>
                <CardDescription>Broad signal for whether the product supports repeat use without manipulative pressure.</CardDescription>
            </CardHeader>
            <CardContent>
                <Progress value={retention_score} label="Retention loop score" />
            </CardContent>
        </Card>}

        <FindingList findings={display_findings} />
    </AppShell>;
}
