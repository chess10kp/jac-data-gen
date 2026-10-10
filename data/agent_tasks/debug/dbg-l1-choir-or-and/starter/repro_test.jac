import from choir { Part, enrol, SectionCheck }

test "only active singers with two rehearsals count" {
    enrol("eve", Part.ALTO, 1);
    s = enrol("old", Part.ALTO, 5);
    s.active = False;
    enrol("fay", Part.ALTO, 2);
    w = root spawn SectionCheck(minimum=1);
    assert w.reports[0]["ALTO"] == 1;
}
