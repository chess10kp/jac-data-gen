"""Generic query walkers for dashboards and search."""


import from ..domain.edges { Captured, Contains, Placed }
import from ..domain.nodes { Alert, CostBaseline, DiningHall, MealService, MenuCycle, MenuItem, Recommendation, Reviewer, ScrapeJob, Station, TrendPoint, WasteBin, WasteLineItem, WasteRecord }
walker :pub SearchFoodByKeyword {
    has keyword: str;
    has limit: int = 20;
    has results: list[dict] = [];

    can start with Root entry {
        visit [-->][?:WasteLineItem];
    }

    can `match with WasteLineItem entry {
        if len(self.results) >= self.limit {
            disengage;
        }
        if self.keyword.lower() in here.food.lower() {
            self.results.append({
                "line_id": here.line_id,
                "food": here.food,
                "category": here.category,
                "weight_oz": here.estimated_weight_oz,
                "cost_usd": here.estimated_cost_usd
            });
        }
    }

    can finish with Root exit {
        report {"keyword": self.keyword, "matches": self.results};
    }
}

walker :pub FindRecordsInDateRange {
    has start_date: str;
    has end_date: str;
    has records: list[dict] = [];

    can start with Root entry {
        visit [-->][?:WasteRecord];
    }

    can check with WasteRecord entry {
        if here.captured_at < self.start_date or here.captured_at > self.end_date {
            skip;
        }
        self.records.append({
            "record_id": here.record_id,
            "captured_at": here.captured_at,
            "severity": here.severity,
            "total_cost_usd": here.total_cost_usd,
            "bin_id": here.bin_id
        });
    }

    can finish with Root exit {
        report {
            "start_date": self.start_date,
            "end_date": self.end_date,
            "records": self.records
        };
    }
}

walker :pub CountByNodeType {
    has counts: dict[str, int] = {};

    can start with Root entry {
        self.counts["DiningHall"] = len([root -->][?:DiningHall]);
        self.counts["MealService"] = len([root -->][?:MealService]);
        self.counts["Station"] = len([root -->][?:Station]);
        self.counts["MenuItem"] = len([root -->][?:MenuItem]);
        self.counts["WasteBin"] = len([root -->][?:WasteBin]);
        self.counts["WasteRecord"] = len([root -->][?:WasteRecord]);
        self.counts["WasteLineItem"] = len([root -->][?:WasteLineItem]);
        self.counts["Recommendation"] = len([root -->][?:Recommendation]);
        self.counts["Alert"] = len([root -->][?:Alert]);
        self.counts["Reviewer"] = len([root -->][?:Reviewer]);
        self.counts["TrendPoint"] = len([root -->][?:TrendPoint]);
        self.counts["CostBaseline"] = len([root -->][?:CostBaseline]);
        self.counts["ScrapeJob"] = len([root -->][?:ScrapeJob]);
        self.counts["MenuCycle"] = len([root -->][?:MenuCycle]);
        report {"counts": self.counts};
    }
}

walker :pub FindHighAvoidabilityItems {
    has threshold_pct: float = 75.0;
    has results: list[dict] = [];

    can start with Root entry {
        visit [-->][?:WasteLineItem];
    }

    can check with WasteLineItem entry {
        if here.avoidable and here.estimated_portion_wasted_pct >= self.threshold_pct {
            self.results.append({
                "food": here.food,
                "category": here.category,
                "portion_wasted_pct": here.estimated_portion_wasted_pct,
                "weight_oz": here.estimated_weight_oz
            });
        }
    }

    can finish with Root exit {
        report {"threshold_pct": self.threshold_pct, "items": self.results};
    }
}

walker :pub GraphHealthCheck {
    has halls: int = 0;
    has orphan_bins: int = 0;
    has empty_records: int = 0;
    has unreviewed: int = 0;

    can start with Root entry {
        self.halls = len([root -->][?:DiningHall]);
        for b in [root -->][?:WasteBin] {
            if b.hall_id == "" {
                self.orphan_bins += 1;
            }
        }
        for r in [root -->][?:WasteRecord] {
            lines = len([r ->:Contains:->][?:WasteLineItem]);
            if lines == 0 {
                self.empty_records += 1;
            }
            if not r.approved {
                self.unreviewed += 1;
            }
        }
        report {
            "halls": self.halls,
            "orphan_bins": self.orphan_bins,
            "empty_records": self.empty_records,
            "unreviewed_records": self.unreviewed
        };
    }
}

walker :pub MenuItemsWithoutCategory {
    has items: list[str] = [];

    can start with Root entry {
        visit [-->][?:MenuItem];
    }

    can check with MenuItem entry {
        if here.category == "other" or here.category == "" {
            self.items.append(here.name);
        }
    }

    can finish with Root exit {
        report {"uncategorized": self.items, "count": len(self.items)};
    }
}

walker :pub BinOccupancyReport {
    has hall_id: str;
    has bins: list[dict] = [];

    can start with Root entry {
        visit [-->][?:DiningHall, hall_id == self.hall_id];
    }

    can walk with DiningHall entry {
        visit [->:Placed:->][?:WasteBin];
    }

    can tally with WasteBin entry {
        record_count = len([here ->:Captured:->][?:WasteRecord]);
        self.bins.append({
            "bin_id": here.bin_id,
            "station_label": here.station_label,
            "record_count": record_count
        });
    }

    can finish with Root exit {
        report {"hall_id": self.hall_id, "bins": self.bins};
    }
}

walker :pub LastCapturedPerHall {
    has per_hall: dict[str, str] = {};

    can start with Root entry {
        visit [-->][?:DiningHall];
    }

    can walk with DiningHall entry {
        latest = "";
        for b in [here ->:Placed:->][?:WasteBin] {
            for r in [b ->:Captured:->][?:WasteRecord] {
                if r.captured_at > latest {
                    latest = r.captured_at;
                }
            }
        }
        self.per_hall[here.hall_id] = latest;
    }

    can finish with Root exit {
        report {"per_hall_last_captured": self.per_hall};
    }
}
