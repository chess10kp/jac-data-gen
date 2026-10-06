"""Walkers that traverse dining halls, meal services, and stations."""


import from ..domain.edges { Features, Hosts }
import from ..domain.nodes { DiningHall, MealService, Station }
walker :pub ListDiningHalls {
    has campus_filter: str = "";
    has only_active: bool = True;
    has results: list[dict] = [];

    can start with Root entry {
        visit [-->];
    }

    can collect with DiningHall entry {
        if self.only_active and not here.active {
            skip;
        }
        if self.campus_filter != "" and here.campus != self.campus_filter {
            skip;
        }
        self.results.append({
            "hall_id": here.hall_id,
            "name": here.name,
            "campus": here.campus,
            "capacity": here.seating_capacity,
            "avg_daily_covers": here.avg_daily_covers
        });
    }

    can finish with Root exit {
        report {
            "halls": self.results,
            "count": len(self.results)
        };
    }
}

walker :pub GetHallSchedule {
    has hall_id: str;
    has week_of: str = "";
    has services: list[dict] = [];

    can start with Root entry {
        visit [-->][?:DiningHall, hall_id == self.hall_id];
    }

    can walk_services with DiningHall entry {
        visit [->:Hosts:->][?:MealService];
    }

    can collect_service with MealService entry {
        if self.week_of != "" and not here.service_date.startswith(self.week_of) {
            skip;
        }
        self.services.append({
            "service_id": here.service_id,
            "meal_period": here.meal_period,
            "date": here.service_date,
            "covers": here.covers_served,
            "stations": here.station_count
        });
    }

    can finish with Root exit {
        report {
            "hall_id": self.hall_id,
            "services": self.services
        };
    }
}

walker :pub CountStationsPerHall {
    has totals: dict[str, int] = {};
    has current_hall: str = "";

    can start with Root entry {
        visit [-->][?:DiningHall];
    }

    can enter_hall with DiningHall entry {
        self.current_hall = here.hall_id;
        self.totals[here.hall_id] = 0;
        visit [->:Hosts:->->:Features:->][?:Station];
    }

    can count_station with Station entry {
        self.totals[self.current_hall] = self.totals[self.current_hall] + 1;
    }

    can finish with Root exit {
        report self.totals;
    }
}

walker :pub FindActiveServices {
    has service_date: str;
    has meal_period: str = "";
    has matched: list[str] = [];

    can start with Root entry {
        visit [-->][?:DiningHall, active == True];
    }

    can scan with DiningHall entry {
        visit [->:Hosts:->][?:MealService, service_date == self.service_date];
    }

    can record with MealService entry {
        if self.meal_period != "" and here.meal_period != self.meal_period {
            skip;
        }
        self.matched.append(here.service_id);
    }

    can finish with Root exit {
        report {
            "matched_services": self.matched,
            "count": len(self.matched)
        };
    }
}

walker :pub HallCoverSummary {
    has horizon_days: int = 7;
    has per_hall: dict[str, int] = {};

    can start with Root entry {
        visit [-->][?:DiningHall];
    }

    can tally with DiningHall entry {
        running = 0;
        for svc in [->:Hosts:->][?:MealService] {
            running += svc.covers_served;
        }
        self.per_hall[here.hall_id] = running;
    }

    can finish with Root exit {
        report self.per_hall;
    }
}

walker :pub AttachMealService {
    has hall_id: str;
    has service_id: str;
    has meal_period: str;
    has service_date: str;
    has created: bool = False;

    can start with Root entry {
        visit [-->][?:DiningHall, hall_id == self.hall_id];
    }

    can attach with DiningHall entry {
        new_service = MealService(
            service_id=self.service_id,
            hall_id=self.hall_id,
            meal_period=self.meal_period,
            service_date=self.service_date
        );
        here +>: Hosts(since=self.service_date, recurring=False) :+> new_service;
        self.created = True;
    }

    can finish with Root exit {
        report {"created": self.created, "service_id": self.service_id};
    }
}

walker :pub StationRotationReport {
    has hall_id: str;
    has rotations: list[dict] = [];

    can start with Root entry {
        visit [-->][?:DiningHall, hall_id == self.hall_id];
    }

    can walk with DiningHall entry {
        visit [->:Hosts:->->:Features:->][?:Station];
    }

    can record with Station entry {
        self.rotations.append({
            "station_id": here.station_id,
            "name": here.name,
            "style": here.service_style,
            "rotation_label": here.rotation_label,
            "staffed": here.staffed
        });
    }

    can finish with Root exit {
        report {"hall_id": self.hall_id, "rotations": self.rotations};
    }
}
