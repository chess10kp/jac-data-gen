"""LegalForge AI -- Agent 6: Report Generator Walker"""

import from ..graph.nodes { Contract, Clause, AuditEntry }
import from ..tools.legal_tools { get_timestamp }
import from byllm.lib { Model }

glob llm = Model(model_name="gemini/gemini-2.5-flash");
walker ReportGeneratorWalker {
    """Final walker that collects all findings and generates the audit report."""
    has contradictions: list = [];
    has violations: list = [];
    has proposals: list = [];

    def generate_executive_summary(data: str) -> str
        by llm(
            reason="Generate a professional executive summary for C-suite review. Include: key findings overview, critical risk areas, recommended immediate actions, and estimated legal exposure. Be concise and actionable."
        );

    can collect with Contract entry {
        all_clauses = [-->[?Clause]];
        flagged = [c for c in all_clauses if c.flagged];
        audit_entries = [-->];

        summary_data = (
            f"Contract: {here.title}\n"
            f"Total Clauses: {len(all_clauses)}\n"
            f"Flagged Clauses: {len(flagged)}\n"
            f"Overall Risk Score: {here.risk_score}\n"
            f"Status: {here.status}\n"
            f"Contradictions: {len(self.contradictions)}\n"
            f"Violations: {len(self.violations)}\n"
            f"Proposals: {len(self.proposals)}"
        );

        executive_summary = self.generate_executive_summary(summary_data);

        report {
            "executive_summary": executive_summary,
            "risk_score": here.risk_score,
            "contract_title": here.title,
            "total_clauses": len(all_clauses),
            "flagged_clauses": len(flagged),
            "contradictions": self.contradictions,
            "violations": self.violations,
            "proposals": self.proposals,
            "audit_trail_count": len(audit_entries)
        };
    }
}
