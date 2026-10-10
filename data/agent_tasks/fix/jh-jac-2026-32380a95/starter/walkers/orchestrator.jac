# walkers/orchestrator.jac

import from agents.entity_extractor { EntityExtractorAgent }
import from agents.timeline_agent { TimelineAgent }
import from agents.fca_mapper { FCAMapperAgent }
import from agents.damage_estimator { DamageEstimatorAgent }

walker QuiTamOrchestrator {
    has extraction_done: bool = False;
    has timeline_done: bool = False;
    has mapping_done: bool = False;
    has damage_done: bool = False;

    can run with Root entry {
        print("QuiTam Orchestrator started!");

        for n in [-->][?:EntityExtractorAgent] {
            visit n;
        }
        for n in [-->][?:TimelineAgent] {
            visit n;
        }
        for n in [-->][?:FCAMapperAgent] {
            visit n;
        }
        for n in [-->][?:DamageEstimatorAgent] {
            visit n;
        }

        print("Orchestration complete!");
    }
}
