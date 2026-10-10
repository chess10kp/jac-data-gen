import from choir { Part, Singer, enrol, SectionCheck }

test "walker reports once" {
    w = root spawn SectionCheck(minimum=1);
    assert len(w.reports) == 1;
    assert w.reports[0] == {"SOPRANO": 0, "ALTO": 0, "TENOR": 0, "BASS": 0};
}

test "enrol adds a singer" {
    s = enrol("zoe", Part.ALTO, 1);
    assert s.name == "zoe";
    assert s.part == Part.ALTO;
    assert s.rehearsals == 1;
    assert s.active == True;
    assert len([root -->[?:Singer]]) == 1;
}

test "empty roster: every part is short when minimum is one" {
    w = root spawn SectionCheck(minimum=1);
    assert w.short == ["SOPRANO", "ALTO", "TENOR", "BASS"];
}

test "minimum zero means nothing is short" {
    w = root spawn SectionCheck(minimum=0);
    assert len(w.short) == 0;
}

test "two rehearsals is the cutoff" {
    enrol("a1", Part.TENOR, 1);
    enrol("a2", Part.TENOR, 2);
    enrol("a3", Part.TENOR, 3);
    enrol("a0", Part.TENOR, 0);
    w = root spawn SectionCheck(minimum=1);
    assert w.reports[0]["TENOR"] == 2;
}

test "inactive singers are not counted" {
    s = enrol("old", Part.SOPRANO, 10);
    s.active = False;
    w = root spawn SectionCheck(minimum=1);
    assert w.reports[0]["SOPRANO"] == 0;
    assert "SOPRANO" in w.short;
}

test "counts are per part" {
    enrol("s1", Part.SOPRANO, 2);
    enrol("a1", Part.ALTO, 2);
    enrol("a2", Part.ALTO, 4);
    enrol("b1", Part.BASS, 3);
    enrol("b2", Part.BASS, 3);
    enrol("b3", Part.BASS, 3);
    w = root spawn SectionCheck(minimum=2);
    assert w.reports[0] == {"SOPRANO": 1, "ALTO": 2, "TENOR": 0, "BASS": 3};
    assert w.short == ["SOPRANO", "TENOR"];
}

test "meeting the minimum exactly is not short" {
    enrol("t1", Part.TENOR, 2);
    enrol("t2", Part.TENOR, 2);
    w = root spawn SectionCheck(minimum=2);
    assert "TENOR" not in w.short;
    assert w.short == ["SOPRANO", "ALTO", "BASS"];
}

test "singers hanging off another node are ignored" {
    s = enrol("lead", Part.BASS, 5);
    s ++> Singer(name="guest", part=Part.BASS, rehearsals=5);
    w = root spawn SectionCheck(minimum=1);
    assert w.reports[0]["BASS"] == 1;
}
