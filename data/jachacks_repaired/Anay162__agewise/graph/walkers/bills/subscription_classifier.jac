"""SubscriptionClassifier walker — classifies subscriptions as essential/useful/wasteful via LLM."""

import from graph.nodes.patient { Patient }
import from graph.nodes.subscription { Subscription }
import from abilities.llm_abilities { classify_subscription_v2 }

walker SubscriptionClassifier {
    has classified_count: int = 0;

    can classify with Patient entry {
        unclassified = [
            n for n in [here-->]
            if isinstance(n, Subscription) and n.classification == "UNKNOWN"
        ];

        for sub in unclassified {
            result = classify_subscription_v2(
                service_name=sub.service_name,
                monthly_cost=sub.monthly_cost,
                usage_evidence=sub.usage_evidence,
                patient_age=75  # typical AgeWise patient
            );
            sub.classification = result.get("classification", "UNKNOWN");
            sub.usage_evidence = result.get("usage_notes", "");
            self.classified_count += 1;
        }

        report {"patient": here.name, "classified": self.classified_count};
    }
}
