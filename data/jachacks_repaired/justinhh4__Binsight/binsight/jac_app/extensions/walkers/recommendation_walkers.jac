"""Walkers for recommendation generation and lifecycle."""


import from ..domain.edges { Belongs, Contains, Suggests }
import from ..domain.nodes { Recommendation, Reviewer, WasteLineItem, WasteRecord }
walker :pub CreateRecommendation {
    has rec_id: str;
    has record_id: str;
    has action: str;
    has generated_at: str;
    has rationale: str = "";
    has priority: str = "medium";
    has target_meal_period: str = "";
    has expected_savings_usd: float = 0.0;
    has model_name: str = "";
    has created: bool = False;

    can start with Root entry {
        visit [-->][?:WasteRecord, record_id == self.record_id];
    }

    can attach with WasteRecord entry {
        rec = Recommendation(
            rec_id=self.rec_id,
            generated_at=self.generated_at,
            priority=self.priority,
            action=self.action,
            rationale=self.rationale,
            target_meal_period=self.target_meal_period,
            expected_savings_usd=self.expected_savings_usd
        );
        here +>: Suggests(
            generated_at=self.generated_at,
            model_name=self.model_name
        ) :+> rec;
        self.created = True;
    }

    can finish with Root exit {
        report {"rec_id": self.rec_id, "created": self.created};
    }
}

walker :pub ListOpenRecommendations {
    has hall_id: str = "";
    has priority_filter: str = "";
    has results: list[dict] = [];

    can start with Root entry {
        visit [-->][?:Recommendation, status == "open"];
    }

    can collect with Recommendation entry {
        if self.priority_filter != "" and here.priority != self.priority_filter {
            skip;
        }
        self.results.append({
            "rec_id": here.rec_id,
            "action": here.action,
            "priority": here.priority,
            "target_meal_period": here.target_meal_period,
            "expected_savings_usd": here.expected_savings_usd,
            "generated_at": here.generated_at
        });
    }

    can finish with Root exit {
        report {"open_recommendations": self.results};
    }
}

walker :pub UpdateRecommendationStatus {
    has rec_id: str;
    has status: str;
    has owner: str = "";
    has updated: bool = False;

    can start with Root entry {
        visit [-->][?:Recommendation, rec_id == self.rec_id];
    }

    can mark with Recommendation entry {
        here.status = self.status;
        if self.owner != "" {
            here.owner = self.owner;
        }
        self.updated = True;
    }

    can finish with Root exit {
        report {"rec_id": self.rec_id, "status": self.status, "updated": self.updated};
    }
}

walker :pub RankRecommendationsBySavings {
    has hall_id: str = "";
    has limit: int = 5;
    has candidates: list[dict] = [];

    can start with Root entry {
        visit [-->][?:Recommendation];
    }

    can collect with Recommendation entry {
        self.candidates.append({
            "rec_id": here.rec_id,
            "action": here.action,
            "savings": here.expected_savings_usd,
            "priority": here.priority
        });
    }

    can finish with Root exit {
        self.candidates.sort(key=lambda (x: dict) -> float { return 0.0 - x["savings"]; });
        top = self.candidates[:self.limit];
        report {"top_by_savings": top};
    }
}

walker :pub AggregateSavingsPotential {
    has horizon_weeks: int = 4;
    has per_hall: dict[str, float] = {};
    has grand_total: float = 0.0;

    can start with Root entry {
        visit [-->][?:Recommendation, status == "open"];
    }

    can tally with Recommendation entry {
        projected = here.expected_savings_usd * self.horizon_weeks;
        self.grand_total += projected;
    }

    can finish with Root exit {
        report {
            "horizon_weeks": self.horizon_weeks,
            "grand_total_usd": self.grand_total,
            "per_hall": self.per_hall
        };
    }
}

walker :pub DismissStaleRecommendations {
    has cutoff_date: str;
    has older_than_days: int = 30;
    has dismissed: list[str] = [];

    can start with Root entry {
        visit [-->][?:Recommendation, status == "open"];
    }

    can inspect with Recommendation entry {
        if here.generated_at < self.cutoff_date {
            here.status = "dismissed";
            self.dismissed.append(here.rec_id);
        }
    }

    can finish with Root exit {
        report {"dismissed": self.dismissed, "count": len(self.dismissed)};
    }
}

walker :pub LinkRecommendationToOwner {
    has rec_id: str;
    has reviewer_id: str;
    has linked: bool = False;

    can start with Root entry {
        visit [-->][?:Recommendation, rec_id == self.rec_id];
    }

    can attach with Recommendation entry {
        for rv in [root -->][?:Reviewer, reviewer_id == self.reviewer_id] {
            here +>: Belongs(role="owner") :+> rv;
            self.linked = True;
            break;
        }
    }

    can finish with Root exit {
        report {"rec_id": self.rec_id, "linked": self.linked, "owner": self.reviewer_id};
    }
}

walker :pub GenerateMenuDelta {
    has record_id: str;
    has threshold_oz: float = 8.0;
    has deltas: list[dict] = [];

    can start with Root entry {
        visit [-->][?:WasteRecord, record_id == self.record_id];
    }

    can walk with WasteRecord entry {
        visit [->:Contains:->][?:WasteLineItem];
    }

    can evaluate with WasteLineItem entry {
        if here.avoidable and here.estimated_weight_oz >= self.threshold_oz {
            self.deltas.append({
                "action": "reduce",
                "item_name": here.food,
                "reason": "avoidable waste above threshold",
                "estimated_savings_usd": here.estimated_cost_usd
            });
        }
    }

    can finish with Root exit {
        report {"record_id": self.record_id, "menu_delta": self.deltas};
    }
}

walker :pub RecommendationsForMealPeriod {
    has meal_period: str;
    has results: list[dict] = [];

    can start with Root entry {
        visit [-->][?:Recommendation, target_meal_period == self.meal_period];
    }

    can collect with Recommendation entry {
        self.results.append({
            "rec_id": here.rec_id,
            "action": here.action,
            "rationale": here.rationale,
            "priority": here.priority
        });
    }

    can finish with Root exit {
        report {"meal_period": self.meal_period, "recommendations": self.results};
    }
}
