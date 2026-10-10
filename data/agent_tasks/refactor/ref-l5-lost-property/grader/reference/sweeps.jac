"""Walkers over every station's shelf."""

import from models { Station, Item, Holds, Category }

"""Unclaimed items matching a description, across all stations."""
walker Search {
    has category: Category;
    has color: str;
    has since_day: int;
    has hits: list[Item] = [];

    can scan with Root entry;
    can enter_station with Station entry;
    can inspect with Item entry;
}

"""Find unclaimed items held longer than the keep window."""
walker Expiry {
    has today: int;
    has keep_days: int;
    has stale: list[Item] = [];

    can scan with Root entry;
    can enter_station with Station entry;
    can inspect with Item entry;
}
