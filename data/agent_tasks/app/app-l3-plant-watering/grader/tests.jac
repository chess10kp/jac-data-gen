import uuid;
import from main { AddPlant, WaterPlant, DuePlants }

def flat(rs: list[any]) -> list[any] {
    if len(rs) == 1 and isinstance(rs[0], list) {
        return rs[0];
    }
    return rs;
}

def due_on(d: str) -> list[any] {
    return flat((root spawn DuePlants(date=d)).reports);
}

test "new plant becomes due after its interval" {
    p = "fern_" + uuid.uuid4().hex[:8];
    root spawn AddPlant(name=p, every_days=3, date="2026-01-01");
    assert p not in due_on("2026-01-03");
    assert p in due_on("2026-01-04");
    assert p in due_on("2026-02-01");
}

test "watering resets the clock" {
    p = "ivy_" + uuid.uuid4().hex[:8];
    root spawn AddPlant(name=p, every_days=7, date="2026-03-01");
    assert p in due_on("2026-03-08");
    root spawn WaterPlant(name=p, date="2026-03-08");
    assert p not in due_on("2026-03-14");
    assert p in due_on("2026-03-15");
}

test "re-adding updates instead of duplicating" {
    p = "palm_" + uuid.uuid4().hex[:8];
    root spawn AddPlant(name=p, every_days=2, date="2026-05-01");
    root spawn AddPlant(name=p, every_days=10, date="2026-05-01");
    due = due_on("2026-05-05");
    assert p not in due;
    due2 = due_on("2026-05-11");
    assert due2.count(p) == 1;
}

test "due list is sorted and reported once" {
    a = "a_" + uuid.uuid4().hex[:8];
    b = "b_" + uuid.uuid4().hex[:8];
    root spawn AddPlant(name=b, every_days=1, date="2026-06-01");
    root spawn AddPlant(name=a, every_days=1, date="2026-06-01");
    r = root spawn DuePlants(date="2026-06-02");
    assert len(r.reports) == 1;
    names = flat(r.reports);
    assert names == sorted(names);
    assert a in names and b in names;
}
