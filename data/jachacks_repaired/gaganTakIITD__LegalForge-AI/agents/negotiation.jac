"""Agent 5: Forge Negotiation Walker -- deterministic redlines."""

import from ..graph.nodes { Contract, Clause }

walker NegotiationWalker {
    has party_perspective: str = "buyer";
    has proposals: list = [];

    can start with Contract entry {
        all_clauses = [-->[?Clause]];
        for c in all_clauses {
            if c.risk_level != "high" and c.risk_level != "critical" and not c.flagged {
                continue;
            }
            kind = c.clause_kind or "general";
            if kind == "indemnification" and "no cap" in c.text.lower() {
                self.proposals.append({
                    "clause_id": c.clause_id,
                    "clause_kind": kind,
                    "original": c.text,
                    "original_text": c.text,
                    "proposed": c.text.replace("with no cap", "capped at the total fees paid under this Agreement"),
                    "proposed_text": c.text.replace("with no cap", "capped at the total fees paid under this Agreement"),
                    "impact": "high",
                    "issue_detected": "Uncapped indemnification creates unlimited liability exposure",
                    "rationale": "Align indemnity cap with liability cap to eliminate contradiction",
                    "confidence": 0.95
                });
            } elif kind == "liability" and "shall not exceed" in c.text.lower() {
                self.proposals.append({
                    "clause_id": c.clause_id,
                    "clause_kind": kind,
                    "original": c.text,
                    "original_text": c.text,
                    "proposed": c.text.replace("$10,000", "the greater of $50,000 or total fees paid"),
                    "proposed_text": c.text.replace("$10,000", "the greater of $50,000 or total fees paid"),
                    "impact": "medium",
                    "issue_detected": "Liability cap may be too low relative to deal value",
                    "rationale": "Increase cap to reflect reasonable exposure while maintaining protection",
                    "confidence": 0.90
                });
            } elif kind == "non_compete" and c.flagged {
                self.proposals.append({
                    "clause_id": c.clause_id,
                    "clause_kind": kind,
                    "original": c.text,
                    "original_text": c.text,
                    "proposed": "Non-compete limited to 2 years within the specific market sector and geographic region of operation.",
                    "proposed_text": "Non-compete limited to 2 years within the specific market sector and geographic region of operation.",
                    "impact": "high",
                    "issue_detected": "Overly broad non-compete may be unenforceable",
                    "rationale": "Narrow scope to comply with FTC Non-Compete Rule and ensure enforceability",
                    "confidence": 0.92
                });
            }
        }
        report {
            "agent": "NegotiationWalker",
            "proposals_generated": len(self.proposals),
            "proposals": self.proposals
        };
    }
}
