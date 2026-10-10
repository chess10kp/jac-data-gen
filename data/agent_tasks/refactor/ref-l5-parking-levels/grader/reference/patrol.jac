"""Walkers that patrol the garage levels."""

import from models { Level, Spot, Car, Contains, Occupied, SpotKind }

"""Pick a free spot of one kind on the lowest level (ties by spot code)."""
walker SpotFinder {
    has kind: SpotKind;
    has best: Spot | None = None;
    has best_level: int = 0;

    can scan with Root entry;
    can survey with Level entry;
}

"""Find a parked car, its spot and its level."""
walker LocateCar {
    has plate: str;
    has car: Car | None = None;
    has spot: Spot | None = None;
    has level: Level | None = None;

    can scan with Root entry;
    can enter_level with Level entry;
    can check with Spot entry;
}
