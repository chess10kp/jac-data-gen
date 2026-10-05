# main.jac

import from agents.entity_extractor { EntityExtractorAgent }
import from agents.timeline_agent { TimelineAgent }
import from agents.fca_mapper { FCAMapperAgent }
import from agents.damage_estimator { DamageEstimatorAgent }
import from nodes.data_nodes {
    DocumentNode,
    EvidenceNode,
    TimelineNode,
    FalsityNode,
    ScientorNode,
    MaterialityNode,
    CausationNode,
    CaseMemoNode
}
import from walkers.run { setup_graph }
import from walkers.ingest { ingest_documents }
import from walkers.orchestrator { QuiTamOrchestrator }

with entry {
    print("=== QuiTam Copilot ===");

    # Step 1 - setup graph
    root spawn setup_graph();

    # Step 2 - load documents
    demo_files = [
        {
            "filename": "billing_records.csv",
            "doc_type": "billing",
            "content": "claim_id,provider,cpt_code,date,amount\nCLM001,Northview Clinic,99215,2022-01-05,173.00\nCLM002,Northview Clinic,99215,2022-01-06,173.00\nCLM003,Northview Clinic,99215,2022-01-07,173.00\nCLM004,Northview Clinic,99215,2022-01-08,173.00\nCLM005,Northview Clinic,99215,2022-01-09,173.00"
        },
        {
            "filename": "internal_emails.txt",
            "doc_type": "email",
            "content": "From: Office Manager\nTo: All Staff\nDate: January 3 2022\n\nTeam - always bill at the 99215 level for all patient visits regardless of complexity. This keeps our revenue up. Do not deviate from this."
        }
    ];

    w = ingest_documents(files=demo_files);
    root spawn w;

    # Step 3 - run orchestrator
    root spawn QuiTamOrchestrator();

    # Step 4 - print final results
    print("");
    print("=== CASE MEMO ===");
    for memo in [root -->][?:CaseMemoNode] {
        print("Defendant:     " + memo.defendant);
        print("False Claims:  " + str(memo.total_false_claims));
        print("Base Damages:  $" + str(memo.base_damages));
        print("Treble Damages: $" + str(memo.treble_damages));
        print("Total Exposure: $" + str(memo.total_exposure));
        print("Summary: " + memo.case_summary);
    }
    print("=================");
}