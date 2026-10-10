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

"""Accumulate one night of burn time and report lamps due for a bulb change."""
walker NightShift {
    has hours: float;
    has due: list[str] = [];

    can start with Root entry {
        visit [-->[?:Lamp]];
    }

    can burn with Lamp entry {
        if not here.lit {
            return;
        }
        factor = 1.5 if here.lens == Lens.FIRST_ORDER else 1.0;
        here.burn_hours += self.hours * factor;
        if here.burn_hours >= 0.9 * here.rated_hours {
            self.due.append(here.station);
        }
    }

    can finish with Root exit {
        report sorted(self.due);
    }
}
