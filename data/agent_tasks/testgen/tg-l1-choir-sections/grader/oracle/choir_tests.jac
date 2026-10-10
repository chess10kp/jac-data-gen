import from choir { Part, Singer, enrol, SectionCheck }

test "empty roster has all four parts at zero" {
    w = root spawn SectionCheck(minimum=1);
    assert len(w.reports) == 1;
    assert w.reports[0] == {"SOPRANO": 0, "ALTO": 0, "TENOR": 0, "BASS": 0};
    assert w.short == ["SOPRANO", "ALTO", "TENOR", "BASS"];
}

test "counts eligible singers per part" {
    enrol("ann", Part.SOPRANO, 3);
    enrol("bea", Part.SOPRANO, 2);
    enrol("cal", Part.TENOR, 5);
    enrol("dov", Part.BASS, 4);
    w = root spawn SectionCheck(minimum=1);
    assert w.reports[0] == {"SOPRANO": 2, "ALTO": 0, "TENOR": 1, "BASS": 1};
    assert w.short == ["ALTO"];
}

test "rehearsal threshold is two" {
    enrol("eve", Part.ALTO, 1);
    enrol("fay", Part.ALTO, 2);
    w = root spawn SectionCheck(minimum=2);
    assert w.reports[0]["ALTO"] == 1;
}

test "inactive singers do not count" {
    s = enrol("gus", Part.BASS, 9);
    s.active = False;
    enrol("hal", Part.BASS, 9);
    w = root spawn SectionCheck(minimum=2);
    assert w.reports[0]["BASS"] == 1;
    assert "BASS" in w.short;
}

test "short list uses declaration order and strict minimum" {
    for i in range(3) {
        enrol(f"s{i}", Part.SOPRANO, 2);
        enrol(f"b{i}", Part.BASS, 2);
    }
    enrol("t0", Part.TENOR, 2);
    enrol("t1", Part.TENOR, 2);
    w = root spawn SectionCheck(minimum=3);
    assert w.short == ["ALTO", "TENOR"];
    assert w.reports[0] == {"SOPRANO": 3, "ALTO": 0, "TENOR": 2, "BASS": 3};
}
