"""Analytics and trend walkers for BinSight dashboards."""


import from ..domain.edges { Captured, Contains, Hosts, Placed }
import from ..domain.nodes { DiningHall, MealService, TrendPoint, WasteBin, WasteLineItem, WasteRecord }
walker :pub WeeklyTrendForHall {
    has hall_id: str;
    has weeks: list[str] = [];
    has points: list[dict[any, any]] = [];

    can start with Root entry {
        visit [-->][?:TrendPoint, hall_id == self.hall_id];
    }

    can collect with TrendPoint entry {
        self.points.append({
            "week_of": here.week_of,
            "avoidable_oz": here.avoidable_weight_oz,
            "unavoidable_oz": here.unavoidable_weight_oz,
            "total_cost_usd": here.total_cost_usd,
            "covers": here.covers_served
        });
    }

    can finish with Root exit {
        self.points.sort(key=lambda (x: dict[any, any]) -> str { return x["week_of"]; });
        report {"hall_id": self.hall_id, "points": self.points};
    }
}

walker :pub ComputeAvoidabilityRatio {
    has hall_id: str;
    has total_avoidable: float = 0.0;
    has total_unavoidable: float = 0.0;

    can start with Root entry {
        visit [-->][?:DiningHall, hall_id == self.hall_id];
    }

    can walk_bins with DiningHall entry {
        visit [->:Placed:->][?:WasteBin];
    }

    can walk_records with WasteBin entry {
        visit [->:Captured:->][?:WasteRecord];
    }

    can tally with WasteRecord entry {
        self.total_avoidable += here.avoidable_weight_oz;
        self.total_unavoidable += here.unavoidable_weight_oz;
    }

    can finish with Root exit {
        combined = self.total_avoidable + self.total_unavoidable;
        ratio = 0.0;
        if combined > 0.0 {
            ratio = self.total_avoidable / combined;
        }
        report {
            "hall_id": self.hall_id,
            "avoidable_oz": self.total_avoidable,
            "unavoidable_oz": self.total_unavoidable,
            "avoidability_ratio": ratio
        };
    }
}

walker :pub CostPerCoverReport {
    has hall_id: str;
    has cost_sum: float = 0.0;
    has covers_sum: int = 0;

    can start with Root entry {
        visit [-->][?:DiningHall, hall_id == self.hall_id];
    }

    can walk with DiningHall entry {
        for svc in [->:Hosts:->][?:MealService] {
            self.covers_sum += svc.covers_served;
        }
        visit [->:Placed:->][?:WasteBin];
    }

    can bins with WasteBin entry {
        visit [->:Captured:->][?:WasteRecord];
    }

    can add_cost with WasteRecord entry {
        self.cost_sum += here.total_cost_usd;
    }

    can finish with Root exit {
        per_cover = 0.0;
        if self.covers_sum > 0 {
            per_cover = self.cost_sum / self.covers_sum;
        }
        report {
            "hall_id": self.hall_id,
            "cost_sum": self.cost_sum,
            "covers_sum": self.covers_sum,
            "cost_per_cover_usd": per_cover
        };
    }
}

walker :pub TopWastedFoods {
    has limit: int = 10;
    has tally: dict[str, float] = {};

    can start with Root entry {
        visit [-->][?:WasteLineItem];
    }

    can add with WasteLineItem entry {
        key = here.food.lower();
        prev = self.tally.get(key, 0.0);
        self.tally[key] = prev + here.estimated_weight_oz;
    }

    can finish with Root exit {
        pairs = [];
        for key in self.tally.keys() {
            pairs.append({"food": key, "weight_oz": self.tally[key]});
        }
        pairs.sort(key=lambda (x: dict[any, any]) -> float { return 0.0 - x["weight_oz"]; });
        top = pairs[:self.limit];
        report {"top_foods": top};
    }
}

walker :pub CategoryBreakdown {
    has tally: dict[str, float] = {};
    has total: float = 0.0;

    can start with Root entry {
        visit [-->][?:WasteLineItem];
    }

    can add with WasteLineItem entry {
        prev = self.tally.get(here.category, 0.0);
        self.tally[here.category] = prev + here.estimated_weight_oz;
        self.total += here.estimated_weight_oz;
    }

    can finish with Root exit {
        rows = [];
        for cat in self.tally.keys() {
            pct = 0.0;
            if self.total > 0.0 {
                pct = (self.tally[cat] / self.total) * 100.0;
            }
            rows.append({"category": cat, "weight_oz": self.tally[cat], "pct": pct});
        }
        rows.sort(key=lambda (x: dict[any, any]) -> float { return 0.0 - x["weight_oz"]; });
        report {"breakdown": rows, "total_oz": self.total};
    }
}

walker :pub SeverityDistribution {
    has counts: dict[str, int] = {};

    can start with Root entry {
        self.counts["low"] = 0;
        self.counts["medium"] = 0;
        self.counts["high"] = 0;
        self.counts["critical"] = 0;
        visit [-->][?:WasteRecord];
    }

    can count with WasteRecord entry {
        sev = here.severity;
        prev = self.counts.get(sev, 0);
        self.counts[sev] = prev + 1;
    }

    can finish with Root exit {
        report {"distribution": self.counts};
    }
}

walker :pub AppendTrendPoint {
    has hall_id: str;
    has point_id: str;
    has week_of: str;
    has avoidable_weight_oz: float;
    has unavoidable_weight_oz: float;
    has total_cost_usd: float;
    has covers_served: int;
    has created: bool = False;

    can start with Root entry {
        tp = TrendPoint(
            point_id=self.point_id,
            hall_id=self.hall_id,
            week_of=self.week_of,
            avoidable_weight_oz=self.avoidable_weight_oz,
            unavoidable_weight_oz=self.unavoidable_weight_oz,
            total_cost_usd=self.total_cost_usd,
            covers_served=self.covers_served
        );
        root ++> tp;
        self.created = True;
        report {"created": self.created, "point_id": self.point_id};
    }
}

walker :pub WeekOverWeekDelta {
    has hall_id: str;
    has baseline_week: str;
    has compare_week: str;
    has baseline_oz: float = 0.0;
    has compare_oz: float = 0.0;

    can start with Root entry {
        visit [-->][?:TrendPoint, hall_id == self.hall_id];
    }

    can collect with TrendPoint entry {
        if here.week_of == self.baseline_week {
            self.baseline_oz = here.avoidable_weight_oz + here.unavoidable_weight_oz;
        }
        if here.week_of == self.compare_week {
            self.compare_oz = here.avoidable_weight_oz + here.unavoidable_weight_oz;
        }
    }

    can finish with Root exit {
        delta = self.compare_oz - self.baseline_oz;
        direction = "flat";
        if delta > 0.0 {
            direction = "up";
        } elif delta < 0.0 {
            direction = "down";
        }
        report {
            "hall_id": self.hall_id,
            "baseline": self.baseline_oz,
            "compare": self.compare_oz,
            "delta_oz": delta,
            "direction": direction
        };
    }
}

walker :pub AverageConfidenceReport {
    has record_id: str = "";
    has count: int = 0;
    has total_conf: float = 0.0;

    can start with Root entry {
        if self.record_id != "" {
            visit [-->][?:WasteRecord, record_id == self.record_id];
        } else {
            visit [-->][?:WasteLineItem];
        }
    }

    can walk with WasteRecord entry {
        visit [->:Contains:->][?:WasteLineItem];
    }

    can add with WasteLineItem entry {
        self.total_conf += here.confidence;
        self.count += 1;
    }

    can finish with Root exit {
        avg = 0.0;
        if self.count > 0 {
            avg = self.total_conf / self.count;
        }
        report {"count": self.count, "avg_confidence": avg};
    }
}

walker :pub CampusRollup {
    has campus: str = "University of Michigan";
    has halls_seen: int = 0;
    has total_cost: float = 0.0;
    has total_weight: float = 0.0;

    can start with Root entry {
        visit [-->][?:DiningHall, campus == self.campus];
    }

    can walk with DiningHall entry {
        self.halls_seen += 1;
        visit [->:Placed:->][?:WasteBin];
    }

    can walk_records with WasteBin entry {
        visit [->:Captured:->][?:WasteRecord];
    }

    can add with WasteRecord entry {
        self.total_cost += here.total_cost_usd;
        self.total_weight += here.total_weight_oz;
    }

    can finish with Root exit {
        report {
            "campus": self.campus,
            "halls": self.halls_seen,
            "total_cost_usd": self.total_cost,
            "total_weight_oz": self.total_weight
        };
    }
}
