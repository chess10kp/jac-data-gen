"""Walkers over the judging graph."""

import from models { Track, Team, Judge, Entered, Covers, Scored }

"""Collect the teams of one track (or every track when `track` is empty)."""
walker Standings {
    has track: str = "";
    has teams: list[Team] = [];

    can scan with Root entry;
    can enter_track with Track entry;
    can collect with Team entry;
}

"""From a judge, walk its tracks and list teams it has not fully scored."""
walker Backlog {
    has todo: list[str] = [];
    has me: Judge | None = None;

    can start with Judge entry;
    can enter_track with Track entry;
    can check with Team entry;
}
