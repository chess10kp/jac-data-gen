import from journal { Journal }

def sample -> Journal {
    j = Journal(athlete="Ana");
    j.log_set("Squat", "2026-03-01", 60.0, 5, "warmup");
    j.log_set("squat", "2026-03-01", 100.0, 5, "work");
    j.log_set("squat", "2026-03-01", 110.0, 3, "work");
    j.log_set("squat", "2026-03-04", 120.0, 1, "work");
    j.log_set("squat", "2026-03-04", 125.0, 1, "fail");
    j.log_set("bench", "2026-03-02", 80.0, 5, "work");
    j.log_set("bench", "2026-03-04", 40.0, 10, "warmup");
    return j;
}

test "only known kinds and positive reps are logged" {
    j = Journal(athlete="Ana");
    assert not j.log_set("squat", "2026-03-01", 100.0, 5, "drop");
    assert not j.log_set("squat", "2026-03-01", 100.0, 0, "work");
    assert len(j.exercises()) == 0;
    assert j.log_set("Deadlift", "2026-03-01", 140.0, 3, "work");
    assert j.exercises() == ["deadlift"];
}

test "best estimated max ignores warmups and failures" {
    j = sample();
    assert j.best("squat") == 124.0;
    assert j.best("SQUAT") == 124.0;
    assert j.best("bench") == 93.3;
    assert j.best("row") == 0.0;
    j.log_set("row", "2026-03-05", 50.0, 8, "warmup");
    assert j.best("row") == 0.0;
    assert j.best_date("row") == "";
}

test "best date prefers the earliest session on a tie" {
    j = sample();
    assert j.best_date("squat") == "2026-03-04";
    j.log_set("squat", "2026-02-20", 120.0, 1, "work");
    assert j.best_date("squat") == "2026-02-20";
    j.log_set("squat", "2026-03-09", 115.0, 5, "work");
    assert j.best("squat") == 134.2;
    assert j.best_date("squat") == "2026-03-09";
    assert j.best_date("nope") == "";
}

test "volume counts work and failed sets since a date" {
    j = sample();
    assert j.volume("squat", "") == 1075.0;
    assert j.volume("squat", "2026-03-02") == 245.0;
    assert j.volume("squat", "2026-03-04") == 245.0;
    assert j.volume("squat", "2026-03-05") == 0.0;
    assert j.volume("bench", "") == 400.0;
    assert j.failures("squat") == 1;
    assert j.failures("bench") == 0;
    j.log_set("bench", "2026-03-06", 85.0, 2, "fail");
    assert j.failures("bench") == 1;
    assert j.volume("bench", "2026-03-03") == 170.0;
}

test "what was trained on a date" {
    j = sample();
    assert j.trained_on("2026-03-04") == ["bench", "squat"];
    assert j.trained_on("2026-03-02") == ["bench"];
    assert len(j.trained_on("2026-01-01")) == 0;
    assert j.exercises() == ["bench", "squat"];
}

test "journals are separate" {
    a = sample();
    b = Journal(athlete="Ben");
    b.log_set("squat", "2026-03-01", 80.0, 1, "work");
    assert b.best("squat") == 82.7;
    assert b.exercises() == ["squat"];
    assert a.best("squat") == 124.0;
    assert len(b.trained_on("2026-03-04")) == 0;
}
