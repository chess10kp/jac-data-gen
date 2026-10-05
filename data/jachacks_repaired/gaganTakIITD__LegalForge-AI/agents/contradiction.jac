"""Agent 2: Contradiction Walker -- deterministic pairwise structural analysis."""

import from ..graph.nodes { Contract, Clause, contradicts }
import from ..tools.clause_classifier { classify_clause, FOUNDATIONAL_KINDS }
import from ..tools.structural_rules { adjudicate_structural_pair }

glob COMPLEMENTARY_PAIRS = [
    ["ip_assignment", "indemnification"],
    ["warranty", "indemnification"],
    ["confidentiality", "indemnification"],
    ["liability", "insurance"],
    ["data_processing", "confidentiality"],
];

walker ContradictionWalker {
    has findings: list = [];
    has comparisons: int = 0;
    has structural_hits: int = 0;

    def _pair_match(k1: str, k2: str, pairs: list) -> bool {
        for p in pairs {
            if len(p) == 2 and k1 in p and k2 in p {
                return True;
            }
        }
        return False;
    }

    def _should_compare(kind_a: str, kind_b: str, linked: bool) -> bool {
        if kind_a in FOUNDATIONAL_KINDS or kind_b in FOUNDATIONAL_KINDS { return False; }
        if kind_a == kind_b and kind_a != "ip_assignment" and kind_a != "indemnification" { return False; }
        if self._pair_match(kind_a, kind_b, COMPLEMENTARY_PAIRS) { return False; }
        if linked { return True; }
        cross_pairs = [
            ["liability", "indemnification"],
            ["liability", "warranty"],
            ["termination", "renewal"],
            ["termination", "confidentiality"],
            ["termination", "non_compete"],
            ["indemnification", "indemnification"],
            ["ip_assignment", "ip_assignment"]
        ];
        if self._pair_match(kind_a, kind_b, cross_pairs) { return True; }
        if kind_a == "general" or kind_b == "general" { return True; }
        return False;
    }

    def _is_mesh_linked(a: Clause, b: Clause) -> bool {
        if b.clause_id and b.clause_id in a.text { return True; }
        if a.clause_id and a.clause_id in b.text { return True; }
        return False;
    }

    can start with Contract entry {
        all_clauses = [-->[?Clause]];
        n = len(all_clauses);
        for i in range(n) {
            a = all_clauses[i];
            if not a.clause_kind {
                a.clause_kind = classify_clause(a.text, a.section);
            }
            for j in range(i + 1, n) {
                b = all_clauses[j];
                if not b.clause_kind {
                    b.clause_kind = classify_clause(b.text, b.section);
                }
                kind_a = a.clause_kind;
                kind_b = b.clause_kind;
                linked = self._is_mesh_linked(a, b);
                if not self._should_compare(kind_a, kind_b, linked) {
                    continue;
                }
                self.comparisons += 1;
                structural = adjudicate_structural_pair(
                    a.text, kind_a,
                    b.text, kind_b
                );
                if not structural or not structural.get("contradicts", False) {
                    continue;
                }
                self.structural_hits += 1;
                a +>:contradicts(
                    severity=str(structural.get("severity", "potential")),
                    explanation=str(structural.get("explanation", "")),
                    confidence=float(structural.get("confidence", 0.85))
                ):+> b;
                a.flagged = True;
                b.flagged = True;
                self.findings.append({
                    "clause_a": a.clause_id,
                    "clause_b": b.clause_id,
                    "kind_a": kind_a,
                    "kind_b": kind_b,
                    "severity": structural.get("severity", "potential"),
                    "explanation": structural.get("explanation", ""),
                    "confidence": structural.get("confidence", 0.85)
                });
            }
        }
        report {
            "agent": "ContradictionWalker",
            "comparisons": self.comparisons,
            "structural_hits": self.structural_hits,
            "contradictions_found": len(self.findings),
            "findings": self.findings
        };
    }
}
