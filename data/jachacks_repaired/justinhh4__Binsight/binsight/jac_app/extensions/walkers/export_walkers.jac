"""Walkers that export structured payloads for dashboards and CSV."""


import from ..domain.edges { Captured, Contains, Placed }
import from ..domain.nodes { Alert, DiningHall, Recommendation, Reviewer, TrendPoint, WasteBin, WasteLineItem, WasteRecord }
walker :pub ExportRecordAsPayload {
    has record_id: str;
    has line_items: list[dict] = [];
    has summary: dict = {};
    has found: bool = False;

    can start with Root entry {
        visit [-->][?:WasteRecord, record_id == self.record_id];
    }

    can walk with WasteRecord entry {
        self.found = True;
        self.summary = {
            "record_id": here.record_id,
            "captured_at": here.captured_at,
            "total_weight_oz": here.total_weight_oz,
            "total_cost_usd": here.total_cost_usd,
            "avoidable_weight_oz": here.avoidable_weight_oz,
            "unavoidable_weight_oz": here.unavoidable_weight_oz,
            "severity": here.severity
        };
        visit [->:Contains:->][?:WasteLineItem];
    }

    can collect with WasteLineItem entry {
        self.line_items.append({
            "food": here.food,
            "category": here.category,
            "weight_oz": here.estimated_weight_oz,
            "cost_usd": here.estimated_cost_usd,
            "avoidable": here.avoidable,
            "confidence": here.confidence
        });
    }

    can finish with Root exit {
        report {
            "found": self.found,
            "summary": self.summary,
            "items": self.line_items
        };
    }
}

walker :pub ExportHallDashboard {
    has hall_id: str;
    has halls_info: dict = {};
    has weekly_points: list[dict] = [];
    has open_recs: list[dict] = [];
    has open_alerts: list[dict] = [];

    can start with Root entry {
        visit [-->][?:DiningHall, hall_id == self.hall_id];
    }

    can fetch with DiningHall entry {
        self.halls_info = {
            "hall_id": here.hall_id,
            "name": here.name,
            "campus": here.campus,
            "capacity": here.seating_capacity
        };
    }

    can finish with Root exit {
        for tp in [root -->][?:TrendPoint, hall_id == self.hall_id] {
            self.weekly_points.append({
                "week_of": tp.week_of,
                "avoidable_oz": tp.avoidable_weight_oz,
                "unavoidable_oz": tp.unavoidable_weight_oz,
                "total_cost_usd": tp.total_cost_usd
            });
        }
        for rc in [root -->][?:Recommendation, status == "open"] {
            self.open_recs.append({
                "rec_id": rc.rec_id,
                "action": rc.action,
                "priority": rc.priority,
                "expected_savings_usd": rc.expected_savings_usd
            });
        }
        for al in [root -->][?:Alert, acknowledged == False] {
            if al.hall_id == self.hall_id or al.hall_id == "" {
                self.open_alerts.append({
                    "alert_id": al.alert_id,
                    "subject": al.subject,
                    "severity": al.severity
                });
            }
        }
        report {
            "hall": self.halls_info,
            "trend": self.weekly_points,
            "recommendations": self.open_recs,
            "alerts": self.open_alerts
        };
    }
}

walker :pub ExportCsvRows {
    has record_id: str;
    has rows: list[list[str]] = [];

    can start with Root entry {
        visit [-->][?:WasteRecord, record_id == self.record_id];
    }

    can walk with WasteRecord entry {
        self.rows.append(["food", "category", "weight_oz", "cost_usd", "avoidable"]);
        visit [->:Contains:->][?:WasteLineItem];
    }

    can add_row with WasteLineItem entry {
        self.rows.append([
            here.food,
            here.category,
            str(here.estimated_weight_oz),
            str(here.estimated_cost_usd),
            str(here.avoidable)
        ]);
    }

    can finish with Root exit {
        report {"record_id": self.record_id, "rows": self.rows};
    }
}

walker :pub ExportTopLine {
    has hall_id: str = "";
    has total_records: int = 0;
    has total_cost: float = 0.0;
    has total_avoidable_oz: float = 0.0;

    can start with Root entry {
        visit [-->][?:WasteRecord];
    }

    can add with WasteRecord entry {
        self.total_records += 1;
        self.total_cost += here.total_cost_usd;
        self.total_avoidable_oz += here.avoidable_weight_oz;
    }

    can finish with Root exit {
        report {
            "hall_id": self.hall_id,
            "total_records": self.total_records,
            "total_cost_usd": self.total_cost,
            "total_avoidable_oz": self.total_avoidable_oz
        };
    }
}

walker :pub ExportReviewerBoard {
    has reviewer_id: str;
    has assigned_halls: list[str] = [];
    has hall_records: dict[str, list] = {};

    can start with Root entry {
        visit [-->][?:Reviewer, reviewer_id == self.reviewer_id];
    }

    can fetch with Reviewer entry {
        self.assigned_halls = here.halls_managed;
        for hid in here.halls_managed {
            self.hall_records[hid] = [];
        }
    }

    can finish with Root exit {
        for hid in self.assigned_halls {
            for dh in [root -->][?:DiningHall, hall_id == hid] {
                for bin in [dh ->:Placed:->][?:WasteBin] {
                    for rec in [bin ->:Captured:->][?:WasteRecord] {
                        self.hall_records[hid].append({
                            "record_id": rec.record_id,
                            "severity": rec.severity,
                            "cost_usd": rec.total_cost_usd
                        });
                    }
                }
            }
        }
        report {
            "reviewer_id": self.reviewer_id,
            "halls": self.assigned_halls,
            "records_by_hall": self.hall_records
        };
    }
}
