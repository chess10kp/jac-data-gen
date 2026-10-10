import from crew { Crew, Department, prep_minutes }
import from schedule { ShootDay, Scene, add_scene, hire, assign }
import from callsheet { CallSheet }

test "prep minutes per department" {
    assert prep_minutes(Department.MAKEUP) == 120;
    assert prep_minutes(Department.WARDROBE) == 90;
    assert prep_minutes(Department.CAMERA) == 60;
    assert prep_minutes(Department.SOUND) == 30;
    assert prep_minutes(Department.GRIP) == 30;
}

test "empty day reports nothing" {
    add_scene(1, "1A", 480, "Pier");
    w = root spawn CallSheet(day=2);
    assert len(w.reports) == 1;
    assert len(w.reports[0]) == 0;
    assert w.locations == 0;
}

test "call time from earliest scene minus prep, zero padded" {
    s1 = add_scene(3, "4A", 540, "Diner");
    s2 = add_scene(3, "4B", 420, "Diner");
    mia = hire("Mia", Department.MAKEUP);
    cam = hire("Cal", Department.CAMERA);
    assign(mia, s1);
    assign(mia, s2);
    assign(cam, s1);
    w = root spawn CallSheet(day=3);
    assert w.reports[0] == ["05:00 Mia (MAKEUP)", "08:00 Cal (CAMERA)"];
    assert w.locations == 1;
}

test "other days do not affect call time" {
    early = add_scene(1, "1A", 300, "Farm");
    late = add_scene(2, "2A", 600, "Barn");
    s = hire("Sol", Department.SOUND);
    assign(s, early);
    assign(s, late);
    assert (root spawn CallSheet(day=2)).reports[0] == ["09:30 Sol (SOUND)"];
}

test "sorted by time then name, distinct locations" {
    a = add_scene(5, "9A", 600, "Roof");
    b = add_scene(5, "9B", 660, "Alley");
    c = add_scene(5, "9C", 700, "Roof");
    zed = hire("Zed", Department.GRIP);
    amy = hire("Amy", Department.GRIP);
    wes = hire("Wes", Department.WARDROBE);
    idle = hire("Ida", Department.CAMERA);
    assign(zed, a);
    assign(amy, a);
    assign(wes, b);
    assign(wes, c);
    w = root spawn CallSheet(day=5);
    assert w.reports[0] == ["09:30 Amy (GRIP)", "09:30 Wes (WARDROBE)", "09:30 Zed (GRIP)"];
    assert w.locations == 2;
}
