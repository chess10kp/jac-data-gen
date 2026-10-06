import from .ui.Badge { Badge }
import from .ui.Card { Card, CardContent }

obj:pub FindingListItem {
    has uid: str = "";
    has severity: str = "medium";
    has category: str = "";
    has legal_safe: bool = True;
    has recommendation: str = "";
    has issue_location: str = "";
    has evidence_ref: str = "";
    has evidence: str = "";
    has proof: str = "";
    has why_it_matters: str = "";
    has research_basis: str = "";
    has fix_guidance: str = "";
    has exact_ui_or_copy_tip: str = "";
    has primary_metric: str = "";
    has guardrail_metric: str = "";
}

def toneForSeverity(severity: str) -> str {
    lowered: str = severity.lower();
    if lowered == "critical" {
        return "danger";
    }
    if lowered == "high" {
        return "warning";
    }
    if lowered == "medium" {
        return "accent";
    }
    return "neutral";
}

def:pub FindingList(findings: list[FindingListItem] = []) -> JsxElement {
    if len(findings) == 0 {
        return <p className="empty-state">No findings yet.</p>;
    }
    return <div className="finding-list">
        {[<Card key={finding.uid} className="finding-card">
            <CardContent>
                <div className="finding-topline">
                    <Badge tone={toneForSeverity(finding.severity)}>{finding.severity}</Badge>
                    <Badge tone="neutral">{finding.category}</Badge>
                    <Badge tone={"success" if finding.legal_safe else "danger"}>{"legal-safe" if finding.legal_safe else "needs review"}</Badge>
                </div>
                <h3>{finding.recommendation}</h3>
                <div className="finding-proof">
                    <div>
                        <dt>Where</dt>
                        <dd>{finding.issue_location}</dd>
                    </div>
                    <div>
                        <dt>Evidence ref</dt>
                        <dd>{finding.evidence_ref}</dd>
                    </div>
                </div>
                <p className="evidence-text">{finding.evidence}</p>
                <dl className="finding-grid">
                    <div>
                        <dt>Proof</dt>
                        <dd>{finding.proof}</dd>
                    </div>
                    <div>
                        <dt>Why it matters</dt>
                        <dd>{finding.why_it_matters}</dd>
                    </div>
                    <div>
                        <dt>Research basis</dt>
                        <dd>{finding.research_basis}</dd>
                    </div>
                    <div>
                        <dt>Fix logic</dt>
                        <dd>{finding.fix_guidance}</dd>
                    </div>
                    <div>
                        <dt>Exact tip</dt>
                        <dd>{finding.exact_ui_or_copy_tip}</dd>
                    </div>
                    <div>
                        <dt>Signals to watch</dt>
                        <dd>{finding.primary_metric} guarded by {finding.guardrail_metric}</dd>
                    </div>
                </dl>
            </CardContent>
        </Card> for finding in findings]}
    </div>;
}
