import from choir { Part, Singer, enrol, SectionCheck }

test "walker reports once" {
    w = root spawn SectionCheck(minimum=1);
    assert len(w.reports) == 1;
}

test "enrol adds a singer" {
    s = enrol("zoe", Part.ALTO, 1);
    assert s.name == "zoe";
}
