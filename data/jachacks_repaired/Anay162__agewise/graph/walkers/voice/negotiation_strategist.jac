"""NegotiationStrategist walker — generates call negotiation strategy from dispute context."""

import from graph.nodes.dispute { Dispute }
import from abilities.llm_abilities { generate_negotiation_strategy }

walker NegotiationStrategist {
    has strategy: dict = {};

    can strategize with Dispute entry {
        self.strategy = generate_negotiation_strategy(
            dispute_type=here.error_type,
            amount_disputed=here.amount_disputed,
            appeal_level=here.appeal_level,
            error_description=here.description,
            payer_name=here.payer_name
        );
        report self.strategy;
    }
}
