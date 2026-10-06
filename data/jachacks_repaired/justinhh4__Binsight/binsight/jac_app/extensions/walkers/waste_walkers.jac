"""Walkers focused on waste bins, waste records, and line item analysis."""


import from ..domain.edges { Captured, Contains, Features, Placed }
import from ..domain.nodes { DiningHall, MenuItem, WasteBin, WasteLineItem, WasteRecord }
walker :pub RegisterWasteBin {
    has bin_id: str;
    has hall_id: str;
    has station_label: str = "";
    has capacity_gallons: float = 23.0;
    has created: bool = False;

    can start with Root entry {
        visit [-->][?:DiningHall, hall_id == self.hall_id];
    }

    can attach with DiningHall entry {
        bin = WasteBin(
            bin_id=self.bin_id,
            hall_id=self.hall_id,
            station_label=self.station_label,
            capacity_gallons=self.capacity_gallons
        );
        here +>: Placed(zone_label=self.station_label) :+> bin;
        self.created = True;
    }

    can finish with Root exit {
        report {"bin_id": self.bin_id, "created": self.created};
    }
}

walker :pub CaptureWasteImage {
    has bin_id: str;
    has image_path: str;
    has captured_at: str;
    has image_media_type: str = "image/jpeg";
    has operator: str = "";
    has recorded: bool = False;

    can start with Root entry {
        visit [-->][?:WasteBin, bin_id == self.bin_id];
    }

    can attach_capture with WasteBin entry {
        here.image_path = self.image_path;
        here.image_media_type = self.image_media_type;
        here.photographed_at = self.captured_at;
        self.recorded = True;
    }

    can finish with Root exit {
        report {
            "bin_id": self.bin_id,
            "captured_at": self.captured_at,
            "operator": self.operator,
            "recorded": self.recorded
        };
    }
}

walker :pub AttachWasteRecord {
    has bin_id: str;
    has record_id: str;
    has captured_at: str;
    has total_weight_oz: float;
    has total_cost_usd: float;
    has avoidable_weight_oz: float;
    has unavoidable_weight_oz: float;
    has severity: str = "low";
    has created: bool = False;

    can start with Root entry {
        visit [-->][?:WasteBin, bin_id == self.bin_id];
    }

    can attach with WasteBin entry {
        rec = WasteRecord(
            record_id=self.record_id,
            bin_id=self.bin_id,
            captured_at=self.captured_at,
            total_weight_oz=self.total_weight_oz,
            total_cost_usd=self.total_cost_usd,
            avoidable_weight_oz=self.avoidable_weight_oz,
            unavoidable_weight_oz=self.unavoidable_weight_oz,
            severity=self.severity
        );
        here +>: Captured(captured_at=self.captured_at) :+> rec;
        self.created = True;
    }

    can finish with Root exit {
        report {"record_id": self.record_id, "created": self.created};
    }
}

walker :pub AddLineItem {
    has record_id: str;
    has line_id: str;
    has food: str;
    has category: str;
    has estimated_weight_oz: float;
    has estimated_portion_wasted_pct: float;
    has estimated_cost_usd: float;
    has avoidable: bool = True;
    has confidence: float = 0.0;
    has matched_menu_item_id: str = "";
    has line_index: int = 0;
    has created: bool = False;

    can start with Root entry {
        visit [-->][?:WasteRecord, record_id == self.record_id];
    }

    can attach with WasteRecord entry {
        line = WasteLineItem(
            line_id=self.line_id,
            food=self.food,
            category=self.category,
            estimated_weight_oz=self.estimated_weight_oz,
            estimated_portion_wasted_pct=self.estimated_portion_wasted_pct,
            estimated_cost_usd=self.estimated_cost_usd,
            avoidable=self.avoidable,
            matched_menu_item_id=self.matched_menu_item_id,
            confidence=self.confidence
        );
        here +>: Contains(line_index=self.line_index) :+> line;
        self.created = True;
    }

    can finish with Root exit {
        report {"line_id": self.line_id, "created": self.created};
    }
}

walker :pub SummarizeRecord {
    has record_id: str;
    has items_counted: int = 0;
    has total_weight: float = 0.0;
    has total_cost: float = 0.0;
    has avoidable_weight: float = 0.0;
    has unavoidable_weight: float = 0.0;
    has category_tally: dict[str, float] = {};

    can start with Root entry {
        visit [-->][?:WasteRecord, record_id == self.record_id];
    }

    can walk with WasteRecord entry {
        visit [->:Contains:->][?:WasteLineItem];
    }

    can tally with WasteLineItem entry {
        self.items_counted += 1;
        self.total_weight += here.estimated_weight_oz;
        self.total_cost += here.estimated_cost_usd;
        if here.avoidable {
            self.avoidable_weight += here.estimated_weight_oz;
        } else {
            self.unavoidable_weight += here.estimated_weight_oz;
        }
        prev = self.category_tally.get(here.category, 0.0);
        self.category_tally[here.category] = prev + here.estimated_weight_oz;
    }

    can finish with Root exit {
        report {
            "record_id": self.record_id,
            "items": self.items_counted,
            "total_weight_oz": self.total_weight,
            "total_cost_usd": self.total_cost,
            "avoidable_weight_oz": self.avoidable_weight,
            "unavoidable_weight_oz": self.unavoidable_weight,
            "category_tally": self.category_tally
        };
    }
}

walker :pub HeaviestCategory {
    has record_id: str;
    has leader: str = "other";
    has leader_weight: float = 0.0;

    can start with Root entry {
        visit [-->][?:WasteRecord, record_id == self.record_id];
    }

    can walk with WasteRecord entry {
        visit [->:Contains:->][?:WasteLineItem];
    }

    can compare with WasteLineItem entry {
        if here.estimated_weight_oz > self.leader_weight {
            self.leader_weight = here.estimated_weight_oz;
            self.leader = here.category;
        }
    }

    can finish with Root exit {
        report {"record_id": self.record_id, "category": self.leader, "weight_oz": self.leader_weight};
    }
}

walker :pub FlagHighSeverity {
    has threshold_cost_usd: float = 40.0;
    has flagged: list[str] = [];

    can start with Root entry {
        visit [-->][?:WasteRecord];
    }

    can inspect with WasteRecord entry {
        if here.total_cost_usd >= self.threshold_cost_usd {
            here.severity = "high";
            self.flagged.append(here.record_id);
        }
    }

    can finish with Root exit {
        report {"flagged": self.flagged, "count": len(self.flagged)};
    }
}

walker :pub MatchLineToMenuItem {
    has record_id: str;
    has hall_id: str;
    has matched_pairs: list[dict] = [];
    has candidate_names: dict[str, str] = {};

    can start with Root entry {
        visit [-->][?:DiningHall, hall_id == self.hall_id];
    }

    can collect_menu with DiningHall entry {
        for mi in [->:Features:->][?:MenuItem] {
            self.candidate_names[mi.name.lower()] = mi.item_id;
        }
        visit [-->][?:WasteRecord, record_id == self.record_id];
    }

    can walk_lines with WasteRecord entry {
        visit [->:Contains:->][?:WasteLineItem];
    }

    can attempt_match with WasteLineItem entry {
        food_lower = here.food.lower();
        for cand in self.candidate_names.keys() {
            if cand in food_lower or food_lower in cand {
                here.matched_menu_item_id = self.candidate_names[cand];
                self.matched_pairs.append({
                    "line_id": here.line_id,
                    "menu_item_id": self.candidate_names[cand]
                });
                break;
            }
        }
    }

    can finish with Root exit {
        report {"record_id": self.record_id, "matched": self.matched_pairs};
    }
}

walker :pub RecordReview {
    has record_id: str;
    has reviewer_id: str;
    has decision: str;
    has reviewed_at: str;
    has notes: str = "";
    has applied: bool = False;

    can start with Root entry {
        visit [-->][?:WasteRecord, record_id == self.record_id];
    }

    can mark with WasteRecord entry {
        here.approved = (self.decision == "approved");
        here.reviewer = self.reviewer_id;
        self.applied = True;
    }

    can finish with Root exit {
        report {"record_id": self.record_id, "applied": self.applied, "decision": self.decision};
    }
}

walker :pub ListRecordsForHall {
    has hall_id: str;
    has min_severity: str = "low";
    has records: list[dict] = [];

    can start with Root entry {
        visit [-->][?:DiningHall, hall_id == self.hall_id];
    }

    can walk_bins with DiningHall entry {
        visit [->:Placed:->][?:WasteBin];
    }

    can walk_records with WasteBin entry {
        visit [->:Captured:->][?:WasteRecord];
    }

    can collect with WasteRecord entry {
        self.records.append({
            "record_id": here.record_id,
            "captured_at": here.captured_at,
            "severity": here.severity,
            "cost_usd": here.total_cost_usd
        });
    }

    can finish with Root exit {
        report {"hall_id": self.hall_id, "records": self.records};
    }
}
