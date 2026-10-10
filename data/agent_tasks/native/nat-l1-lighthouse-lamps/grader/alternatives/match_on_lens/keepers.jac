"""Coastal lighthouse lamps. One Lamp node per station, attached to root."""

enum Lens {
    FIRST_ORDER,
    SECOND_ORDER,
    THIRD_ORDER
}

node Lamp {
    has station: str;
    has lens: Lens = Lens.THIRD_ORDER;
    has burn_hours: float = 0.0;
    has rated_hours: float = 1000.0;
    has lit: bool = True;
}

def add_lamp(station: str, lens: Lens, burn_hours: float, rated_hours: float, lit: bool) -> Lamp {
    return root ++> Lamp(station=station, lens=lens, burn_hours=burn_hours, rated_hours=rated_hours, lit=lit);
}

def wear_factor(lens: Lens) -> float {
    match lens {
        case Lens.FIRST_ORDER:
            return 1.5;
        case _:
            return 1.0;
    }
}

walker NightShift {
    has hours: float;
    has due: list[str] = [];

    can start with Root entry {
        visit [-->[?:Lamp, lit == True]];
    }

    can burn with Lamp entry {
        here.burn_hours = here.burn_hours + self.hours * wear_factor(here.lens);
        remaining = here.rated_hours * 0.9 - here.burn_hours;
        if remaining <= 0 {
            idx = 0;
            while idx < len(self.due) and self.due[idx] < here.station {
                idx += 1;
            }
            self.due.insert(idx, here.station);
        }
    }

    can finish with Root exit {
        report self.due;
    }
}
