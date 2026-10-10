"""LegalForge AI -- Agent 4: Risk Scorer Walker"""

import from graph.nodes { Clause, Contract }

walker RiskScorerWalker {
    has total_score: float = 0.0;
    has clause_count: int = 0;
    has clause_scores: list = [];

    can start with Contract entry {
        all_clauses = [-->(`?Clause)];
        for c in all_clauses {
            contradiction_edges = [<-->];
            has_contradictions = len(contradiction_edges) > 0 if contradiction_edges else False;
            has_violations = c.flagged;
            score = 0.25;
            if has_contradictions { score = min(1.0, score + 0.15); }
            if has_violations { score = min(1.0, score + 0.2); }
            c.risk_score = score;
            if score >= 0.8 { c.risk_level = "critical"; }
            elif score >= 0.5 { c.risk_level = "high"; }
            elif score >= 0.3 { c.risk_level = "medium"; }
            else { c.risk_level = "low"; }
            self.total_score += score;
            self.clause_count += 1;
            self.clause_scores.append({
                "clause_id": c.clause_id,
                "score": score,
                "risk_level": c.risk_level
            });
        }
        here.risk_score = self.total_score / max(self.clause_count, 1);
        if here.risk_score >= 0.6 { here.status = "flagged"; }
        else { here.status = "analyzed"; }
        report {
            "overall_risk": here.risk_score,
            "clauses_analyzed": self.clause_count,
            "clause_scores": self.clause_scores
        };
    }
}
