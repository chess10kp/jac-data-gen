import from main { Exercise, SetEntry, find_exercise, LogSet, PersonalBest, Volume }

def log(ex: str, date: str, w: float, reps: int) -> SetEntry {
    return (root spawn LogSet(exercise=ex, date=date, weight=w, reps=reps)).reports[0];
}

def pb(ex: str) -> dict {
    r = root spawn PersonalBest(exercise=ex);
    assert len(r.reports) == 1;
    return r.reports[0];
}

def vol(ex: str, since: str) -> float {
    r = root spawn Volume(exercise=ex, since=since);
    assert len(r.reports) == 1;
    return r.reports[0];
}

test "e1rm uses the Epley formula rounded to one decimal" {
    assert SetEntry(date="d", weight=100.0, reps=1).e1rm() == 103.3;
    assert SetEntry(date="d", weight=100.0, reps=10).e1rm() == 133.3;
    assert SetEntry(date="d", weight=60.0, reps=5).e1rm() == 70.0;
    assert SetEntry(date="d", weight=80.0, reps=0).e1rm() == 80.0;
}

test "exercises are stored lower-case and reused" {
    s = log("Squat", "2026-01-01", 100.0, 5);
    assert s.weight == 100.0;
    assert s.reps == 5;
    log("SQUAT", "2026-01-02", 100.0, 5);
    exs = [root -->[?:Exercise]];
    assert len(exs) == 1;
    assert exs[0].name == "squat";
    assert find_exercise("sQuAt") is not None;
    assert len([exs[0] -->[?:SetEntry]]) == 2;
}

test "personal best picks the highest e1rm" {
    log("bench", "2026-01-01", 80.0, 5);
    log("bench", "2026-01-08", 90.0, 1);
    log("bench", "2026-01-15", 70.0, 12);
    b = pb("Bench");
    assert b["e1rm"] == 98.0;
    assert b["date"] == "2026-01-15";
}

test "personal best tie goes to the earliest date" {
    log("row", "2026-02-10", 60.0, 5);
    log("row", "2026-02-01", 60.0, 5);
    log("row", "2026-02-20", 60.0, 5);
    b = pb("row");
    assert b["e1rm"] == 70.0;
    assert b["date"] == "2026-02-01";
}

test "personal best for an unknown exercise" {
    b = pb("curl");
    assert b["e1rm"] == 0.0;
    assert b["date"] == "";
}

test "volume sums weight times reps since a date inclusive" {
    log("dead", "2026-03-01", 100.0, 5);
    log("dead", "2026-03-05", 120.0, 3);
    log("dead", "2026-03-09", 140.0, 1);
    assert vol("dead", "2026-01-01") == 1000.0;
    assert vol("dead", "2026-03-05") == 500.0;
    assert vol("dead", "2026-03-06") == 140.0;
    assert vol("dead", "2026-04-01") == 0.0;
}

test "volume is per exercise and case insensitive" {
    log("press", "2026-01-01", 40.0, 10);
    log("dip", "2026-01-01", 10.0, 10);
    assert vol("PRESS", "2026-01-01") == 400.0;
    assert vol("nothing", "2026-01-01") == 0.0;
}
