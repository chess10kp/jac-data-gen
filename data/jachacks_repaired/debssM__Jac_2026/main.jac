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

# ── API WALKER 1: ANALYZE CASE ───────────────────────
# Called by React frontend with uploaded files
walker analyze_case {
    has files: list = [];

    can run with Root entry {

        # Setup graph if not already done
        agents = [-->][?:EntityExtractorAgent];
        if len(agents) == 0 {
            root spawn setup_graph();
        }

        # Ingest uploaded documents
        w = ingest_documents(files=self.files);
        root spawn w;

        # Run all 4 agents via orchestrator
        root spawn QuiTamOrchestrator();

        # Return case memo to frontend
        for memo in [-->][?:CaseMemoNode] {
            report {
                "defendant": memo.defendant,
                "total_false_claims": memo.total_false_claims,
                "base_damages": memo.base_damages,
                "treble_damages": memo.treble_damages,
                "total_exposure": memo.total_exposure,
                "case_summary": memo.case_summary,
                "overall_strength": memo.overall_strength
            };
        }
    }
}

# ── API WALKER 2: GET FCA SCORES ─────────────────────
# Returns element scores for the score bars in the UI
walker get_scores {
    can run with Root entry {
        scores = {
            "falsity": 0.0,
            "scienter": 0.0,
            "materiality": 0.0,
            "causation": 0.0
        };

        for n in [-->][?:FalsityNode] {
            scores["falsity"] = n.strength_score;
        }
        for n in [-->][?:ScientorNode] {
            scores["scienter"] = n.strength_score;
        }
        for n in [-->][?:MaterialityNode] {
            scores["materiality"] = n.strength_score;
        }
        for n in [-->][?:CausationNode] {
            scores["causation"] = n.strength_score;
        }

        report scores;
    }
}

# ── API WALKER 3: GET EVIDENCE ───────────────────────
# Returns all extracted evidence items
walker get_evidence {
    can run with Root entry {
        for ev in [-->][?:EvidenceNode] {
            report {
                "type": ev.evidence_type,
                "description": ev.description,
                "source": ev.source_doc,
                "confidence": ev.confidence
            };
        }
    }
}

# ── API WALKER 4: GET TIMELINE ───────────────────────
# Returns fraud timeline
walker get_timeline {
    can run with Root entry {
        for tl in [-->][?:TimelineNode] {
            report {
                "fraud_start": tl.fraud_start,
                "fraud_end": tl.fraud_end,
                "total_duration_months": tl.total_duration_months,
                "events": tl.events
            };
        }
    }
}

# ── API WALKER 5: RESET ──────────────────────────────
# Clears all data for a fresh analysis
walker reset_case {
    can run with Root entry {
        # Remove all document nodes
        for doc in [-->][?:DocumentNode] {
            del doc;
        }
        # Remove all evidence nodes
        for ev in [-->][?:EvidenceNode] {
            del ev;
        }
        # Remove all timeline nodes
        for tl in [-->][?:TimelineNode] {
            del tl;
        }
        # Remove all FCA element nodes
        for n in [-->][?:FalsityNode] {
            del n;
        }
        for n in [-->][?:ScientorNode] {
            del n;
        }
        for n in [-->][?:MaterialityNode] {
            del n;
        }
        for n in [-->][?:CausationNode] {
            del n;
        }
        # Remove case memo
        for memo in [-->][?:CaseMemoNode] {
            del memo;
        }

        report "Case reset complete";
    }
}

# ── ENTRY POINT ──────────────────────────────────────
# Runs once when jac start main.jac is executed
with entry {
    root spawn setup_graph();
    print("QuiTam Copilot API ready!");
}
