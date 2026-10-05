"""
LegalForge AI — Main Entry Point
Multi-Agent Contract Intelligence Platform built with Jac.
Orchestrates 6 walker agents through a knowledge graph.
"""

import from graph.nodes { Contract }
import from agents.parser_agent { ParserAgent }
import from agents.mesh_enrichment { MeshEnrichmentWalker }
import from agents.contradiction { ContradictionWalker }
import from agents.compliance { ComplianceWalker }
import from agents.risk_scorer { RiskScorerWalker }
import from agents.negotiation { NegotiationWalker }
import from agents.report_generator { ReportGeneratorWalker }
import from security.auth_gate { AuthGateWalker }
walker AnalyzeContract {
    """Master orchestrator: runs all 6 agents in sequence."""
    has contract_text: str = "";
    has contract_title: str = "Untitled Contract";
    has jurisdiction: str = "US";
    has party_perspective: str = "buyer";
    has user_role: str = "analyst";

    can orchestrate with Root entry {
        # Step 1: Auth Gate
        auth_result = here spawn AuthGateWalker(
            user_role=self.user_role,
            requested_action="analyze"
        );
        if not auth_result.reports or not auth_result.reports[-1].get("authorized", False) {
            report {"error": "Unauthorized"};
            disengage;
        }

        # Step 2: Parse Contract
        parse_result = here spawn ParserAgent(
            contract_text=self.contract_text,
            contract_title=self.contract_title
        );

        # Step 3: Find the contract node
        kids = [-->];
        if not kids {
            report {"error": "Failed to parse contract"};
            disengage;
        }
        contract_node = kids[-1];

        # Step 4: Mesh + analysis walkers on the contract graph
        mesh_result = contract_node spawn MeshEnrichmentWalker();

        contradiction_result = contract_node spawn ContradictionWalker();

        # Compliance checking
        compliance_result = contract_node spawn ComplianceWalker(
            jurisdiction=self.jurisdiction
        );

        # Risk scoring
        risk_result = contract_node spawn RiskScorerWalker();

        # Negotiation
        negotiation_result = contract_node spawn NegotiationWalker(
            party_perspective=self.party_perspective
        );

        # Step 5: Generate Report
        report_result = contract_node spawn ReportGeneratorWalker(
            contradictions=contradiction_result.get("findings", []) if isinstance(contradiction_result, dict) else [],
            violations=compliance_result.get("violations", []) if isinstance(compliance_result, dict) else [],
            proposals=negotiation_result.get("proposals", []) if isinstance(negotiation_result, dict) else []
        );

        report {
            "status": "complete",
            "parse": parse_result,
            "mesh": mesh_result,
            "contradictions": contradiction_result,
            "compliance": compliance_result,
            "risk": risk_result,
            "negotiation": negotiation_result,
            "report": report_result
        };
    }
}

with entry {
    print("LegalForge AI -- Multi-Agent Contract Intelligence Platform");
    print("   6 Walker Agents | Knowledge Graph | 4-Layer Security");
    print("");
    print("   Walkers run on the OSP graph (spawn + edges + by llm()).");
    print("   Live API: jac serve service.jac");
    print("   then open the React UI at http://localhost:3000");
}
