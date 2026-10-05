"""
LegalForge AI - Jac Cloud Service (native walker runtime)
"""

import from graph.nodes { Contract }
import from agents.parser_agent { ParserAgent }
import from agents.mesh_enrichment { MeshEnrichmentWalker }
import from agents.contradiction { ContradictionWalker }
import from agents.compliance { ComplianceWalker }
import from agents.risk_scorer { RiskScorerWalker }
import from agents.negotiation { NegotiationWalker }
import from agents.graph_export { GraphExportWalker }
import from security.auth_gate { authenticate_user, verify_token, check_permission }
import from jac_data.samples { SAMPLES }
import from tools.legal_tools { sanitize_for_report }


node ContractRef {
    has contract_id: str = "";
    has title: str = "";
    has risk_score: float = 0.0;
}


walker login {
    has username: str = "";
    has password: str = "";

    obj __specs__ {
        static has auth: bool = False;
    }

    can do with Root entry {
        result = authenticate_user(self.username, self.password);
        report result;
    }
}


walker list_samples {
    obj __specs__ {
        static has auth: bool = False;
        static has methods: list = ["get", "post"];
    }

    can do with Root entry {
        items = [];
        for sid in SAMPLES.keys() {
            sample = SAMPLES.get(sid, {});
            items.append({
                "id": sid,
                "title": sample.get("title", sid),
                "length": len(sample.get("text", ""))
            });
        }
        report {"samples": items};
    }
}


walker get_sample {
    has sample_id: str = "";

    obj __specs__ {
        static has auth: bool = False;
    }

    can do with Root entry {
        sample = SAMPLES.get(self.sample_id, {});
        out = sample if sample else {"error": "Sample not found", "sample_id": self.sample_id};
        report out;
    }
}


walker analyze {
    has contract_text: str = "";
    has title: str = "Uploaded Contract";
    has jurisdiction: str = "US";
    has party_perspective: str = "buyer";
    has token: str = "";

    obj __specs__ {
        static has auth: bool = False;
    }

    can orchestrate with Root entry {
        ref = ContractRef(title=self.title);
        here ++> ref;

        if self.token {
            user = verify_token(self.token);
            auth_ok = user.get("valid", False) and check_permission(user.get("role", ""), "analyze");
            if not auth_ok {
                report {"error": "Invalid or expired token"};
                disengage;
            }
        }

        parse_w = here spawn ParserAgent(
            contract_text=self.contract_text,
            contract_title=self.title
        );
        parse_result = parse_w.result if parse_w.result else {};

        contract_kids = [-->[?Contract]];
        if not contract_kids {
            report {"error": "Failed to parse contract", "parse": parse_result, "status": "error"};
            disengage;
        }
        contract_node: Contract = contract_kids[-1];
        contract_node.jurisdiction = self.jurisdiction;

        mesh_w = contract_node spawn MeshEnrichmentWalker();
        contra_w = contract_node spawn ContradictionWalker();
        compliance_w = contract_node spawn ComplianceWalker(jurisdiction=self.jurisdiction);
        risk_w = contract_node spawn RiskScorerWalker();
        nego_w = contract_node spawn NegotiationWalker(party_perspective=self.party_perspective);

        contra_findings = contra_w.findings;
        viols = compliance_w.violations;
        props = nego_w.proposals;

        flagged_count = 0;
        for cs in risk_w.clause_scores {
            if isinstance(cs, dict) and cs.get("risk_level", "") in ["high", "critical"] {
                flagged_count += 1;
            }
        }

        ref.contract_id = contract_node.title;
        ref.risk_score = contract_node.risk_score;

        export_w = contract_node spawn GraphExportWalker(
            contradictions=contra_findings,
            violations=viols,
            proposals=props,
            report_text=(
                f"Analyzed {parse_result.get('clauses', 0)} clauses. "
                f"Found {len(contra_findings)} contradiction(s), {len(viols)} violation(s), "
                f"{len(props)} proposal(s). Risk: {contract_node.risk_score}."
            ),
            contract_intent={
                "deal_thesis": f"Analysis of {self.title}",
                "jurisdiction": self.jurisdiction,
                "party_perspective": self.party_perspective,
                "document_type": "GENERIC"
            }
        );

        ui_payload = export_w.payload if export_w.payload else {};
        if not ui_payload {
            ui_payload = {"status": "error", "error": "No payload", "title": self.title};
        }
        ui_payload["parse_result"] = parse_result;
        ui_payload["contradiction_result"] = {
            "agent": "ContradictionWalker",
            "comparisons": contra_w.comparisons,
            "structural_hits": contra_w.structural_hits,
            "contradictions_found": len(contra_findings),
            "findings": contra_findings
        };
        ui_payload["compliance_result"] = {
            "agent": "ComplianceWalker",
            "jurisdiction": self.jurisdiction,
            "violations_found": len(viols),
            "violations": viols
        };
        ui_payload["risk_result"] = {
            "overall_risk": contract_node.risk_score,
            "clauses_analyzed": risk_w.clause_count,
            "clause_scores": risk_w.clause_scores
        };
        ui_payload["negotiation_result"] = {
            "agent": "NegotiationWalker",
            "proposals_generated": len(props),
            "proposals": props
        };
        ui_payload["report_result"] = {
            "executive_summary": (
                f"Executive Summary: {self.title}\n"
                f"Analyzed {parse_result.get('clauses', 0)} clauses. "
                f"Found {len(contra_findings)} contradiction(s), {len(viols)} violation(s), "
                f"{len(props)} proposal(s). Risk score: {contract_node.risk_score}. "
                f"{flagged_count} high/critical clauses."
            ),
            "risk_score": contract_node.risk_score,
            "contract_title": self.title,
            "total_clauses": parse_result.get("clauses", 0),
            "flagged_clauses": flagged_count,
            "contradictions": contra_findings,
            "violations": viols,
            "proposals": props,
            "audit_trail_count": 0
        };
        ui_payload["mesh_result"] = {
            "agent": "MeshEnrichmentWalker",
            "reference_edges": mesh_w.reference_edges,
            "modifies_edges": mesh_w.modifies_edges
        };
        ui_payload["runtime"] = "jac-walkers";
        ui_payload["demo_mode"] = False;
        ui_payload["status"] = "complete";
        report sanitize_for_report(ui_payload);
    }
}


walker health {
    obj __specs__ {
        static has auth: bool = False;
        static has methods: list = ["get", "post"];
    }

    can do with Root entry {
        contracts = [-->];
        clauses = [-->];
        report {
            "status": "healthy",
            "runtime": "jac-walkers",
            "contracts_in_graph": len(contracts),
            "clauses_in_graph": len(clauses)
        };
    }
}


with entry {
    ::py::
    import os
    from pathlib import Path
    try:
        from dotenv import load_dotenv
        root_env = Path(__file__).parent / ".env"
        backend_env = Path(__file__).parent / "backend" / ".env"
        if root_env.exists():
            load_dotenv(root_env, override=True)
        elif backend_env.exists():
            load_dotenv(backend_env, override=True)
        _key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY") or os.getenv("OPENAI_API_KEY", "")
        if _key:
            os.environ.setdefault("GEMINI_API_KEY", _key)
            os.environ.setdefault("GOOGLE_API_KEY", _key)
    except ImportError:
        pass
    ::py::
    print("LegalForge AI -- Jac native walker runtime (service.jac)");
    print("Run:  jac serve service.jac");
}
