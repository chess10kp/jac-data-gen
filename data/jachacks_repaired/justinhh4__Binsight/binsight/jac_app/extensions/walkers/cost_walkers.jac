"""Cost baseline management and cost computation walkers."""


import from ..domain.edges { Contains }
import from ..domain.nodes { CostBaseline, WasteLineItem, WasteRecord }
walker :pub UpsertCostBaseline {
    has baseline_id: str;
    has category: str;
    has dollars_per_oz: float;
    has last_updated: str;
    has sourced_from: str = "USDA";
    has updated: bool = False;

    can start with Root entry {
        existing_found = False;
        for b in [root -->][?:CostBaseline, category == self.category] {
            b.dollars_per_oz = self.dollars_per_oz;
            b.sourced_from = self.sourced_from;
            b.last_updated = self.last_updated;
            existing_found = True;
            self.updated = True;
            break;
        }
        if not existing_found {
            baseline = CostBaseline(
                baseline_id=self.baseline_id,
                category=self.category,
                dollars_per_oz=self.dollars_per_oz,
                sourced_from=self.sourced_from,
                last_updated=self.last_updated
            );
            root ++> baseline;
            self.updated = True;
        }
        report {"category": self.category, "updated": self.updated};
    }
}

walker :pub GetCostBaselines {
    has rows: list[dict] = [];

    can start with Root entry {
        visit [-->][?:CostBaseline];
    }

    can collect with CostBaseline entry {
        self.rows.append({
            "category": here.category,
            "dollars_per_oz": here.dollars_per_oz,
            "sourced_from": here.sourced_from,
            "last_updated": here.last_updated
        });
    }

    can finish with Root exit {
        report {"baselines": self.rows};
    }
}

walker :pub EstimateCostForLine {
    has food: str;
    has category: str;
    has estimated_weight_oz: float;
    has estimated_cost_usd: float = 0.0;

    can start with Root entry {
        visit [-->][?:CostBaseline, category == self.category];
    }

    can compute with CostBaseline entry {
        self.estimated_cost_usd = here.dollars_per_oz * self.estimated_weight_oz;
        disengage;
    }

    can finish with Root exit {
        report {
            "food": self.food,
            "category": self.category,
            "weight_oz": self.estimated_weight_oz,
            "estimated_cost_usd": self.estimated_cost_usd
        };
    }
}

walker :pub RepriceRecord {
    has record_id: str;
    has recomputed_total: float = 0.0;
    has rates: dict[str, float] = {};

    can start with Root entry {
        for b in [root -->][?:CostBaseline] {
            self.rates[b.category] = b.dollars_per_oz;
        }
        visit [-->][?:WasteRecord, record_id == self.record_id];
    }

    can walk with WasteRecord entry {
        visit [->:Contains:->][?:WasteLineItem];
    }

    can reprice with WasteLineItem entry {
        rate = self.rates.get(here.category, 0.0);
        new_cost = rate * here.estimated_weight_oz;
        here.estimated_cost_usd = new_cost;
        self.recomputed_total += new_cost;
    }

    can finish with Root exit {
        report {"record_id": self.record_id, "recomputed_total_usd": self.recomputed_total};
    }
}

walker :pub AnnualCostProjection {
    has weekly_average_usd: float;
    has weeks_per_year: int = 36;
    has projected_usd: float = 0.0;

    can start with Root entry {
        self.projected_usd = self.weekly_average_usd * self.weeks_per_year;
        report {
            "weekly_average_usd": self.weekly_average_usd,
            "weeks_per_year": self.weeks_per_year,
            "projected_usd": self.projected_usd
        };
    }
}

walker :pub CategoryCostLeaders {
    has limit: int = 5;
    has tally: dict[str, float] = {};

    can start with Root entry {
        visit [-->][?:WasteLineItem];
    }

    can add with WasteLineItem entry {
        prev = self.tally.get(here.category, 0.0);
        self.tally[here.category] = prev + here.estimated_cost_usd;
    }

    can finish with Root exit {
        rows = [];
        for cat in self.tally.keys() {
            rows.append({"category": cat, "cost_usd": self.tally[cat]});
        }
        rows.sort(key=lambda (x: dict) -> float { return 0.0 - x["cost_usd"]; });
        top = rows[:self.limit];
        report {"top_cost_categories": top};
    }
}

walker :pub CompareCostToBaseline {
    has record_id: str;
    has original_cost: float = 0.0;
    has baseline_cost: float = 0.0;
    has rates: dict[str, float] = {};

    can start with Root entry {
        for b in [root -->][?:CostBaseline] {
            self.rates[b.category] = b.dollars_per_oz;
        }
        visit [-->][?:WasteRecord, record_id == self.record_id];
    }

    can walk with WasteRecord entry {
        self.original_cost = here.total_cost_usd;
        visit [->:Contains:->][?:WasteLineItem];
    }

    can compute with WasteLineItem entry {
        rate = self.rates.get(here.category, 0.0);
        self.baseline_cost += rate * here.estimated_weight_oz;
    }

    can finish with Root exit {
        delta = self.original_cost - self.baseline_cost;
        report {
            "record_id": self.record_id,
            "original_cost": self.original_cost,
            "baseline_cost": self.baseline_cost,
            "delta": delta
        };
    }
}
