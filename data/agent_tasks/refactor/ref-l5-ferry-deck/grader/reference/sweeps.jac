"""Walkers over the sailings."""

import from models { Sailing, Booking, Holds }

"""Find a booking by reference and the sailing that holds it."""
walker LocateBooking {
    has ref: str;
    has found: Booking | None = None;
    has at: Sailing | None = None;

    can scan with Root entry;
    can look with Sailing entry;
}

"""Count passengers across every sailing on one day."""
walker DayCount {
    has day: int;
    has total: int = 0;

    can scan with Root entry;
    can tally with Sailing entry;
}
