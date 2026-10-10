"""Greenhouse watering schedule. Beds hang off root; each Bed Grows Plants."""

node Bed {
    has code: str;
}

node Plant {
    has species: str;
    has interval_days: int;
    has last_watered: int;
}

edge Grows: Bed --> Plant {}

# TODO: PlantIn, WaterBed, DueOn, Uproot walkers
