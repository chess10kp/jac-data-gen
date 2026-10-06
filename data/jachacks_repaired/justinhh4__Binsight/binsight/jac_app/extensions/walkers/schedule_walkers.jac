"""Walkers for scheduling, windows, and meal period timing."""


import from ..domain.nodes { DiningHall }
node ServiceWindow {
    has window_id: str;
    has hall_id: str;
    has meal_period: str;
    has starts_at: str;
    has ends_at: str;
    has day_of_week: str = "";
    has active: bool = True;
}

node Holiday {
    has holiday_id: str;
    has name: str;
    has occurs_on: str;
    has hall_closed: bool = True;
}

edge OpensWindow {
    has since: str = "";
    has note: str = "";
}

walker :pub DefineServiceWindow {
    has window_id: str;
    has hall_id: str;
    has meal_period: str;
    has starts_at: str;
    has ends_at: str;
    has day_of_week: str = "";
    has created: bool = False;

    can start with Root entry {
        visit [-->][?:DiningHall, hall_id == self.hall_id];
    }

    can attach with DiningHall entry {
        w = ServiceWindow(
            window_id=self.window_id,
            hall_id=self.hall_id,
            meal_period=self.meal_period,
            starts_at=self.starts_at,
            ends_at=self.ends_at,
            day_of_week=self.day_of_week
        );
        here +>: OpensWindow(since=self.starts_at) :+> w;
        self.created = True;
    }

    can finish with Root exit {
        report {"window_id": self.window_id, "created": self.created};
    }
}

walker :pub ListWindowsForHall {
    has hall_id: str;
    has windows: list[dict] = [];

    can start with Root entry {
        visit [-->][?:DiningHall, hall_id == self.hall_id];
    }

    can walk with DiningHall entry {
        visit [->:OpensWindow:->][?:ServiceWindow];
    }

    can collect with ServiceWindow entry {
        self.windows.append({
            "window_id": here.window_id,
            "meal_period": here.meal_period,
            "starts_at": here.starts_at,
            "ends_at": here.ends_at,
            "day_of_week": here.day_of_week,
            "active": here.active
        });
    }

    can finish with Root exit {
        report {"hall_id": self.hall_id, "windows": self.windows};
    }
}

walker :pub DisableWindow {
    has window_id: str;
    has disabled: bool = False;

    can start with Root entry {
        visit [-->][?:ServiceWindow, window_id == self.window_id];
    }

    can mark with ServiceWindow entry {
        here.active = False;
        self.disabled = True;
    }

    can finish with Root exit {
        report {"window_id": self.window_id, "disabled": self.disabled};
    }
}

walker :pub RegisterHoliday {
    has holiday_id: str;
    has name: str;
    has occurs_on: str;
    has hall_closed: bool = True;
    has created: bool = False;

    can start with Root entry {
        h = Holiday(
            holiday_id=self.holiday_id,
            name=self.name,
            occurs_on=self.occurs_on,
            hall_closed=self.hall_closed
        );
        root ++> h;
        self.created = True;
        report {"holiday_id": self.holiday_id, "created": self.created};
    }
}

walker :pub IsHallOpenOnDate {
    has target_date: str;
    has hall_open: bool = True;
    has reason: str = "";

    can start with Root entry {
        for h in [root -->][?:Holiday, occurs_on == self.target_date] {
            if h.hall_closed {
                self.hall_open = False;
                self.reason = h.name;
            }
        }
        report {
            "target_date": self.target_date,
            "hall_open": self.hall_open,
            "reason": self.reason
        };
    }
}

walker :pub MealPeriodForTime {
    has hall_id: str;
    has time_of_day: str;
    has matched_period: str = "";

    can start with Root entry {
        visit [-->][?:DiningHall, hall_id == self.hall_id];
    }

    can walk with DiningHall entry {
        visit [->:OpensWindow:->][?:ServiceWindow, active == True];
    }

    can check with ServiceWindow entry {
        if self.time_of_day >= here.starts_at and self.time_of_day <= here.ends_at {
            self.matched_period = here.meal_period;
            disengage;
        }
    }

    can finish with Root exit {
        report {
            "hall_id": self.hall_id,
            "time_of_day": self.time_of_day,
            "meal_period": self.matched_period
        };
    }
}

walker :pub UpcomingHolidays {
    has on_or_after: str;
    has limit: int = 10;
    has holidays: list[dict] = [];

    can start with Root entry {
        visit [-->][?:Holiday];
    }

    can collect with Holiday entry {
        if here.occurs_on >= self.on_or_after {
            self.holidays.append({
                "holiday_id": here.holiday_id,
                "name": here.name,
                "occurs_on": here.occurs_on,
                "hall_closed": here.hall_closed
            });
        }
    }

    can finish with Root exit {
        self.holidays.sort(key=lambda (h: dict) -> str { return h["occurs_on"]; });
        top = self.holidays[:self.limit];
        report {"upcoming": top};
    }
}
