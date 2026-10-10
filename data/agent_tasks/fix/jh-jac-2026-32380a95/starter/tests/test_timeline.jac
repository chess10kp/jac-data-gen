# ============================================================
# TEST — Timeline Agent (standalone)
# ============================================================

include "nodes/data_nodes.jac";
include "agents/timeline_agent.jac";
include "walkers/orchestrator.jac";

walker test_timeline {
    can run with `root entry {
        # Create the agent
        agent = TimelineAgent();
        here ++> agent;

        # Feed it fake evidence (skip extractor)
        here ++> EvidenceNode(
            evidence_type="pattern",
            description="Dr. Smith billed CPT 99215 at 3x national avg from Jan-Jun 2024",
            source_doc="billing.csv",
            confidence=0.9
        );
        here ++> EvidenceNode(
            evidence_type="amount",
            description="Total claims jumped from 50k/month to 200k/month in March 2024",
            source_doc="billing.csv",
            confidence=0.85
        );

        print("=== TESTING TIMELINE AGENT ===");
        print("Feeding 2 fake evidence items...");

        # Visit

    }
    can check with TimelineNode entry {
        print(f"Fraud period: {here.fraud_start} to {here.fraud_end}");
        print(f"Duration: {here.total_duration_months} months");
        print(f"Events: {len(here.events)}");
        for event in here.events {
            print(f"  {event.get('date', '?')}: {event.get('event', '?')}");
        }
    }
}

with entry {
    test_timeline() spawn root
}
