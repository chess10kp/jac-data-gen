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
