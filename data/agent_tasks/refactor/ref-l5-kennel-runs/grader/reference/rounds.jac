"""Walkers that sweep the kennel runs."""

import from models { Run, Stay, Hosts }

"""Find the smallest free run that fits (ties broken by run code)."""
walker PickRun {
    has need: int;
    has start: int;
    has nights: int;
    has best: Run | None = None;

    can scan with Root entry;
    can consider with Run entry;
}

"""Collect `RUN:dog` lines for every stay covering one night."""
walker NightList {
    has night: int;
    has lines: list[str] = [];

    can scan with Root entry;
    can look with Run entry;
}

"""Remove every stay of one dog."""
walker Departure {
    has dog: str;
    has removed: int = 0;

    can scan with Root entry;
    can clear with Run entry;
}

"""Sum the locked nightly price over one dog's stays."""
walker Billing {
    has dog: str;
    has total: int = 0;

    can scan with Root entry;
    can enter_run with Run entry;
    can charge with Stay entry;
}
