import uuid;
import from main { LogSet, PersonalBest, Volume }

def get(x: any, k: str) -> any {
    return x[k] if isinstance(x, dict) else getattr(x, k);
}

test "personal best by estimated 1rm" {
    ex = "bench" + uuid.uuid4().hex[:6];
    root spawn LogSet(exercise=ex, date="2026-03-01", weight=60.0, reps=5);
    root spawn LogSet(exercise=ex, date="2026-03-03", weight=65.0, reps=3);
    root spawn LogSet(exercise=ex, date="2026-03-05", weight=55.0, reps=10);
    r = root spawn PersonalBest(exercise=ex);
    assert len(r.reports) == 1;
    best = r.reports[0];
    assert abs(get(best, "e1rm") - 73.3) < 1e-6;
    assert get(best, "date") == "2026-03-05";
}

test "ties go to the earliest date and names are case insensitive" {
    ex = "squat" + uuid.uuid4().hex[:6];
    root spawn LogSet(exercise=ex.upper(), date="2026-04-02", weight=100.0, reps=3);
    root spawn LogSet(exercise=ex, date="2026-04-01", weight=100.0, reps=3);
    best = (root spawn PersonalBest(exercise=ex.capitalize())).reports[0];
    assert abs(get(best, "e1rm") - 110.0) < 1e-6;
    assert get(best, "date") == "2026-04-01";
}

test "no sets" {
    best = (root spawn PersonalBest(exercise="never" + uuid.uuid4().hex[:6])).reports[0];
    assert get(best, "e1rm") == 0.0 and get(best, "date") == "";
}

test "volume since a date" {
    ex = "row" + uuid.uuid4().hex[:6];
    root spawn LogSet(exercise=ex, date="2026-02-27", weight=50.0, reps=10);
    root spawn LogSet(exercise=ex, date="2026-03-01", weight=60.0, reps=5);
    root spawn LogSet(exercise=ex, date="2026-03-02", weight=62.5, reps=8);
    assert abs((root spawn Volume(exercise=ex, since="2026-03-01")).reports[0] - 800.0) < 1e-6;
    assert abs((root spawn Volume(exercise=ex, since="2026-01-01")).reports[0] - 1300.0) < 1e-6;
    assert abs((root spawn Volume(exercise=ex, since="2027-01-01")).reports[0]) < 1e-6;
}
