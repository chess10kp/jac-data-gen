# run_real_pipeline.jac
# Runs the full 4-agent Jac pipeline against the real files in data/

import from nodes.data_nodes {
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
import from helpers { load_case_files }

with entry {
    print("=== QuiTam Copilot: REAL DATA RUN ===");

    root spawn setup_graph();

    case_files = load_case_files("data");
    print("Loaded " + str(len(case_files)) + " files from data/");

    w = ingest_documents(files=case_files);
    root spawn w;

    root spawn QuiTamOrchestrator();

    print("");
    print("=== EVIDENCE ===");
    for e in [root -->][?:EvidenceNode] {
        print("- [" + e.evidence_type + "] " + e.description + " (source: " + e.source_doc + ", conf: " + str(e.confidence) + ")");
    }

    print("");
    print("=== TIMELINE ===");
    for t in [root -->][?:TimelineNode] {
        print("Start: " + t.fraud_start + "  End: " + t.fraud_end + "  Duration: " + str(t.total_duration_months) + " months");
        for ev in t.events {
            print("  - " + str(ev));
        }
    }

    print("");
    print("=== FCA ELEMENTS ===");
    for f in [root -->][?:FalsityNode] {
        print("Falsity: " + str(f.strength_score) + " (" + f.falsity_type + ")");
    }
    for s in [root -->][?:ScientorNode] {
        print("Scienter: " + str(s.strength_score) + " (" + s.knowledge_type + ")");
    }
    for m in [root -->][?:MaterialityNode] {
        print("Materiality: " + str(m.strength_score) + " (relied: " + str(m.government_relied) + ")");
    }
    for c in [root -->][?:CausationNode] {
        print("Causation: " + str(c.strength_score));
    }

    print("");
    print("=== CASE MEMO ===");
    for memo in [root -->][?:CaseMemoNode] {
        print("Defendant:      " + memo.defendant);
        print("False Claims:   " + str(memo.total_false_claims));
        print("Base Damages:   $" + str(memo.base_damages));
        print("Treble Damages: $" + str(memo.treble_damages));
        print("Total Exposure: $" + str(memo.total_exposure));
        print("Overall Strength: " + str(memo.overall_strength));
        print("Summary: " + memo.case_summary);
    }
    print("=================");
}
