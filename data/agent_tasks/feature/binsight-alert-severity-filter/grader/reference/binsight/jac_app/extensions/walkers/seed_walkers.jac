"""Seed and fixture walkers that bootstrap reference data."""


import from ..domain.edges { Features, Hosts }
import from ..domain.nodes { Alert, CostBaseline, DiningHall, MealService, Reviewer, ScrapeJob, Station, TrendPoint }
walker :pub SeedUmichHalls {
    has created: list[str] = [];

    can start with Root entry {
        halls: list[dict[str, any]] = [
            {"hall_id": "bursley", "name": "Bursley Dining Hall", "capacity": 950, "covers": 1600},
            {"hall_id": "south_quad", "name": "South Quad Dining Hall", "capacity": 820, "covers": 1400},
            {"hall_id": "north_quad", "name": "North Quad Dining Hall", "capacity": 540, "covers": 900},
            {"hall_id": "east_quad", "name": "East Quad Dining Hall", "capacity": 620, "covers": 1050},
            {"hall_id": "mojo", "name": "Mosher-Jordan Dining Hall", "capacity": 700, "covers": 1150},
            {"hall_id": "markley", "name": "Markley Dining Hall", "capacity": 880, "covers": 1500},
            {"hall_id": "twigs_oxford", "name": "Twigs at Oxford", "capacity": 260, "covers": 400}
        ];
        for h in halls {
            dh = DiningHall(
                hall_id=h["hall_id"],
                name=h["name"],
                seating_capacity=h["capacity"],
                avg_daily_covers=h["covers"]
            );
            root ++> dh;
            self.created.append(h["hall_id"]);
        }
        report {"created_halls": self.created};
    }
}

walker :pub SeedCostBaselines {
    has as_of: str;
    has created: int = 0;

    can start with Root entry {
        defaults: list[dict[str, any]] = [
            {"id": "cb_protein", "cat": "protein", "rate": 0.34},
            {"id": "cb_grain", "cat": "grain", "rate": 0.08},
            {"id": "cb_dairy", "cat": "dairy", "rate": 0.15},
            {"id": "cb_fruit", "cat": "fruit", "rate": 0.11},
            {"id": "cb_vegetable", "cat": "vegetable", "rate": 0.09},
            {"id": "cb_beverage", "cat": "beverage", "rate": 0.05},
            {"id": "cb_other", "cat": "other", "rate": 0.10}
        ];
        for d in defaults {
            cb = CostBaseline(
                baseline_id=d["id"],
                category=d["cat"],
                dollars_per_oz=d["rate"],
                sourced_from="USDA",
                last_updated=self.as_of
            );
            root ++> cb;
            self.created += 1;
        }
        report {"created": self.created, "as_of": self.as_of};
    }
}

walker :pub SeedDemoMealServices {
    has hall_id: str;
    has service_date: str;
    has created: list[str] = [];

    can start with Root entry {
        visit [-->][?:DiningHall, hall_id == self.hall_id];
    }

    can seed with DiningHall entry {
        periods = ["breakfast", "lunch", "dinner"];
        idx = 0;
        for p in periods {
            svc_id = self.hall_id + "_" + self.service_date + "_" + p;
            svc = MealService(
                service_id=svc_id,
                hall_id=self.hall_id,
                meal_period=p,
                service_date=self.service_date,
                covers_served=0,
                station_count=0
            );
            here +>: Hosts(since=self.service_date, recurring=True) :+> svc;
            self.created.append(svc_id);
            idx += 1;
        }
    }

    can finish with Root exit {
        report {"hall_id": self.hall_id, "created": self.created};
    }
}

walker :pub SeedDefaultStations {
    has hall_id: str;
    has created: list[str] = [];

    can start with Root entry {
        visit [-->][?:DiningHall, hall_id == self.hall_id];
    }

    can attach with DiningHall entry {
        stations = [
            {"id": "grill", "name": "Grill", "style": "staffed"},
            {"id": "deli", "name": "Deli", "style": "staffed"},
            {"id": "salad", "name": "Salad Bar", "style": "self-serve"},
            {"id": "global", "name": "Global Kitchen", "style": "staffed"},
            {"id": "dessert", "name": "Dessert", "style": "self-serve"},
            {"id": "beverages", "name": "Beverages", "style": "self-serve"}
        ];
        for svc in [->:Hosts:->][?:MealService] {
            for s in stations {
                st_id = svc.service_id + "_" + s["id"];
                station = Station(
                    station_id=st_id,
                    name=s["name"],
                    service_style=s["style"]
                );
                svc +>: Features(rotation_slot=0) :+> station;
                self.created.append(st_id);
            }
        }
    }

    can finish with Root exit {
        report {"hall_id": self.hall_id, "stations_created": len(self.created)};
    }
}

walker :pub SeedDemoReviewers {
    has created: int = 0;

    can start with Root entry {
        demo = [
            {"id": "rv_alex", "name": "Alex Chen", "role": "manager"},
            {"id": "rv_sam", "name": "Sam Rivera", "role": "sustainability_lead"},
            {"id": "rv_jordan", "name": "Jordan Park", "role": "chef"},
            {"id": "rv_morgan", "name": "Morgan Lee", "role": "auditor"}
        ];
        for r in demo {
            rv = Reviewer(
                reviewer_id=r["id"],
                name=r["name"],
                role=r["role"]
            );
            root ++> rv;
            self.created += 1;
        }
        report {"reviewers_created": self.created};
    }
}

walker :pub PurgeDemoData {
    has confirm_token: str;
    has removed_nodes: int = 0;

    can start with Root entry {
        if self.confirm_token != "BINSIGHT_DEMO_RESET" {
            report {"removed_nodes": 0, "confirmed": False};
            disengage;
        }
        for tp in [root -->][?:TrendPoint] {
            root del--> tp;
            self.removed_nodes += 1;
        }
        for al in [root -->][?:Alert] {
            root del--> al;
            self.removed_nodes += 1;
        }
        for sj in [root -->][?:ScrapeJob] {
            root del--> sj;
            self.removed_nodes += 1;
        }
        report {"removed_nodes": self.removed_nodes, "confirmed": True};
    }
}
