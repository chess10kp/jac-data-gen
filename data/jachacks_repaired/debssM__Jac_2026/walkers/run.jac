# walkers/run.jac

import from agents.entity_extractor { EntityExtractorAgent }
import from agents.timeline_agent { TimelineAgent }
import from agents.fca_mapper { FCAMapperAgent }
import from agents.damage_estimator { DamageEstimatorAgent }

walker setup_graph {
    can setup with Root entry {
        print("Walker reached root!");

        extractor = EntityExtractorAgent();
        here ++> extractor;

        timeline = TimelineAgent();
        here ++> timeline;

        mapper = FCAMapperAgent();
        here ++> mapper;

        estimator = DamageEstimatorAgent();
        here ++> estimator;

        print("Graph setup complete!");
        print("EntityExtractorAgent connected");
        print("TimelineAgent connected");
        print("FCAMapperAgent connected");
        print("DamageEstimatorAgent connected");
    }
}
