import from byllm.llm { Model }
import from nodes.data_nodes {
    EvidenceNode,
    TimelineNode,
    FalsityNode,
    ScientorNode,
    MaterialityNode,
    CausationNode
}
import from agents.fca_mapper { FCAMapperAgent }
import from walkers.run { setup_graph }

glob llm = Model(model_name="claude-sonnet-4-20250514");

walker test_orchestrator {
    has mapping_done: bool = False;

    can run with Root entry {
        print("Orchestrator started");
        print("Visiting FCAMapperAgent directly...");

        for n in [-->][?:FCAMapperAgent] {
            visit n;
        }
    }
}

with entry {
    print("=== Testing FCA Agent ===");

    root spawn setup_graph();

    ev1 = EvidenceNode();
    ev1.evidence_type = "billing_anomaly";
    ev1.description = "Northview Clinic billed 99215 for 100% of visits";
    ev1.source_doc = "billing_records.csv";
    ev1.confidence = 0.95;
    root ++> ev1;

    ev2 = EvidenceNode();
    ev2.evidence_type = "email_evidence";
    ev2.description = "Manager email instructs staff to always bill 99215";
    ev2.source_doc = "internal_emails.txt";
    ev2.confidence = 0.99;
    root ++> ev2;

    tl = TimelineNode();
    tl.fraud_start = "2022-01-01";
    tl.fraud_end = "2023-12-31";
    tl.total_duration_months = 24;
    tl.events = [];
    root ++> tl;

    root spawn test_orchestrator();

    print("=== Test Complete ===");
}