"""Serialize Jac OSP graph to UI JSON (nodes, links, clauses, findings)."""

import from ..graph.nodes { Contract, Clause }


walker GraphExportWalker {
    has contradictions: list = [];
    has violations: list = [];
    has proposals: list = [];
    has report_text: str = "";
    has contract_intent: dict = {};
    has payload: dict = {};

    def clause_label(c: Clause) -> str {
        cid = c.clause_id if c.clause_id else "?";
        sec = (c.section or "").strip();
        if sec {
            short = sec if len(sec) <= 28 else sec[:26] + "…";
            return f"§{cid} {short}";
        }
        return f"§{cid}";
    }

    can export with Contract entry {
        all_clauses = [-->[?Clause]];
        contract_key = here.title if here.title else "contract";
        clauses_out = [];
        for c in all_clauses {
            ck = c.clause_id if c.clause_id else f"clause-{c.text[:20]}";
            clauses_out.append({
                "id": ck,
                "clause_id": c.clause_id,
                "title": f"Sec. {c.clause_id}" + (f" - {c.section}" if c.section else ""),
                "section": c.section,
                "risk_score": c.risk_score,
                "risk_level": c.risk_level,
                "clause_type": c.clause_type,
                "clause_kind": c.clause_kind,
                "flagged": c.flagged,
                "text": c.text
            });
        }

        id_map = {};
        for c in all_clauses {
            ck = c.clause_id if c.clause_id else f"clause-{c.text[:20]}";
            id_map[c.clause_id] = ck;
        }

        contradictions_out = [];
        for f in self.contradictions {
            contradictions_out.append({
                "clause_a": f.get("clause_a", ""),
                "clause_b": f.get("clause_b", ""),
                "clause_a_id": id_map.get(f.get("clause_a", ""), ""),
                "clause_b_id": id_map.get(f.get("clause_b", ""), ""),
                "severity": f.get("severity", "potential"),
                "description": f.get("explanation", ""),
                "confidence": f.get("confidence", 0)
            });
        }

        compliance_out = [];
        for v in self.violations {
            compliance_out.append({
                "clause": v.get("clause_id", ""),
                "statute": v.get("statute", ""),
                "severity": v.get("severity", "high"),
                "issue": v.get("detail", "")
            });
        }

        proposals_out = [];
        for p in self.proposals {
            proposals_out.append({
                "clause": p.get("clause_id", ""),
                "clause_kind": p.get("clause_kind", ""),
                "original": p.get("original", p.get("original_text", "")),
                "proposed": p.get("proposed", p.get("proposed_text", "")),
                "impact": p.get("impact", "medium"),
                "issue_detected": p.get("issue_detected", ""),
                "rationale": p.get("rationale", "")
            });
        }

        nodes = [{"id": contract_key, "label": here.title, "type": "contract", "risk": here.risk_score}];
        links = [];
        for c in all_clauses {
            ck = c.clause_id if c.clause_id else f"clause-{c.text[:20]}";
            nodes.append({
                "id": ck, "label": self.clause_label(c), "type": "clause",
                "risk": c.risk_score, "risk_level": c.risk_level, "flagged": c.flagged
            });
            links.append({"source": contract_key, "target": ck, "type": "contains"});
        }
        for f in self.contradictions {
            sa = id_map.get(f.get("clause_a", ""), "");
            sb = id_map.get(f.get("clause_b", ""), "");
            if sa and sb {
                links.append({"source": sa, "target": sb, "type": "contradicts"});
            }
        }

        self.payload = {
            "status": "complete",
            "title": here.title,
            "risk_score": here.risk_score,
            "clauses": clauses_out,
            "contradictions": contradictions_out,
            "compliance_issues": compliance_out,
            "proposals": proposals_out,
            "report": self.report_text,
            "contract_intent": self.contract_intent,
            "graph_data": {"nodes": nodes, "links": links}
        };
        # Avoid reporting the full payload: Jac prints reports to stdout and large
        # payloads crash on Windows (OSError 22) when stdout is not a real console.
        # Parent walkers read export_w.payload directly.
        report {"status": "complete", "title": here.title, "clauses": len(clauses_out)};
    }
}
