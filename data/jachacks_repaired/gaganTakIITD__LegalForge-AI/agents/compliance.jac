"""Agent 3: Compliance Walker -- deterministic statute checks."""

import from ..graph.nodes { Contract, Clause, governed_by }
import from ..tools.clause_classifier { FOUNDATIONAL_KINDS }
import from ..tools.structural_rules { has_liability_cap, has_uncapped_indemnity }

walker ComplianceWalker {
    has jurisdiction: str = "US";
    has violations: list = [];

    def _privacy_leak(text: str) -> bool {
        t = text.lower();
        return ("sell" in t or "share" in t) and "personal data" in t and "without" in t and "consent" in t;
    }

    def _non_compete_overreach(text: str) -> bool {
        t = text.lower();
        return ("non-compete" in t or "noncompete" in t or "non compete" in t)
            and ("global" in t or "seven year" in t or "5 year" in t or "five year" in t);
    }

    def _check_gdpr_data_traps(all_clauses: list) -> bool {
        gdpr_clause: Clause | None = None;
        analytics_clause: Clause | None = None;
        for c in all_clauses {
            t = c.text.lower();
            if "gdpr" in t or "ccpa" in t {
                gdpr_clause = c;
            }
            if "user data" in t and ("analytic" in t or "anonymized" in t or "anonymised" in t) {
                analytics_clause = c;
            }
        }
        if gdpr_clause is not None and analytics_clause is not None {
            gdpr_clause.flagged = True;
            analytics_clause.flagged = True;
            self.violations.append({
                "clause_id": gdpr_clause.clause_id,
                "clause_kind": "data_processing",
                "statute": "GDPR Art. 28 / CCPA 1798.100",
                "detail": (
                    "GDPR/CCPA compliance claim conflicts with broad analytics use of User Data "
                    "without subprocessors, lawful basis, or consent flow."
                ),
                "severity": "high",
                "confidence": 0.91
            });
            return True;
        }
        return False;
    }

    can start with Contract entry {
        all_clauses = [-->[?Clause]];
        self._check_gdpr_data_traps(all_clauses);
        cap_clause: Clause | None = None;
        ind_clause: Clause | None = None;
        for c in all_clauses {
            if has_liability_cap(c.text) { cap_clause = c; }
            if has_uncapped_indemnity(c.text) { ind_clause = c; }
        }
        if cap_clause is not None and ind_clause is not None {
            self.violations.append({
                "clause_id": ind_clause.clause_id,
                "clause_kind": "indemnification",
                "statute": "UCC Sec. 2-302",
                "detail": (
                    f"Uncapped indemnity at Sec. {ind_clause.clause_id} vs cap at Sec. {cap_clause.clause_id}."
                ),
                "severity": "high",
                "confidence": 0.93
            });
            ind_clause.flagged = True;
            cap_clause.flagged = True;
            ind_clause +>:governed_by:+> cap_clause;
        }
        for c in all_clauses {
            if c.clause_kind in FOUNDATIONAL_KINDS { continue; }
            if self._privacy_leak(c.text) {
                c.flagged = True;
                self.violations.append({
                    "clause_id": c.clause_id,
                    "clause_kind": c.clause_kind or "data_processing",
                    "statute": "GDPR Art. 6 / CCPA 1798.120",
                    "detail": "Personal-data sale or share without consent.",
                    "severity": "critical",
                    "confidence": 0.95
                });
                continue;
            }
            if c.clause_kind == "liability" and has_liability_cap(c.text) {
                c.flagged = True;
                self.violations.append({
                    "clause_id": c.clause_id,
                    "clause_kind": "liability",
                    "statute": "UCC Sec. 2-302",
                    "detail": "Liability cap may be unconscionable relative to uncapped indemnity elsewhere.",
                    "severity": "high",
                    "confidence": 0.88
                });
            } elif c.clause_kind == "indemnification" and has_uncapped_indemnity(c.text) {
                c.flagged = True;
                self.violations.append({
                    "clause_id": c.clause_id,
                    "clause_kind": "indemnification",
                    "statute": "UCC Sec. 2-302",
                    "detail": "Uncapped indemnification scope appears unconscionable.",
                    "severity": "high",
                    "confidence": 0.90
                });
            } elif c.clause_kind == "non_compete" and self._non_compete_overreach(c.text) {
                c.flagged = True;
                self.violations.append({
                    "clause_id": c.clause_id,
                    "clause_kind": "non_compete",
                    "statute": "FTC Non-Compete Rule",
                    "detail": "Restrictive covenant scope may exceed enforceability under FTC guidance.",
                    "severity": "high",
                    "confidence": 0.91
                });
            } elif c.clause_kind == "data_processing" and ("gdpr" in c.text.lower() or "ccpa" in c.text.lower()) {
                c.flagged = True;
                self.violations.append({
                    "clause_id": c.clause_id,
                    "clause_kind": "data_processing",
                    "statute": "GDPR Art. 28",
                    "detail": "Data-processing terms require subprocessors, retention limits, and lawful basis for personal data.",
                    "severity": "high",
                    "confidence": 0.85
                });
            }
        }
        report {
            "agent": "ComplianceWalker",
            "jurisdiction": self.jurisdiction,
            "violations_found": len(self.violations),
            "violations": self.violations
        };
    }
}
