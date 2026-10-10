import from crew { Crew, Department, prep_minutes }
import from schedule { ShootDay, Scene, shoot_day, add_scene, hire, assign }
import from callsheet { clock, CallSheet }

test "department prep times" {
    assert prep_minutes(Department.MAKEUP) == 120;
    assert prep_minutes(Department.WARDROBE) == 90;
    assert prep_minutes(Department.CAMERA) == 60;
    assert prep_minutes(Department.SOUND) == 30;
    assert prep_minutes(Department.GRIP) == 30;
}

test "clock pads hours and minutes" {
    assert clock(0) == "00:00";
    assert clock(65) == "01:05";
    assert clock(600) == "10:00";
    assert clock(1439) == "23:59";
}

test "shoot_day is reused per day" {
    a = shoot_day(4);
    b = shoot_day(4);
    c = shoot_day(5);
    assert a == b;
    assert a != c;
    add_scene(4, "1", 100, "X");
    assert len([root -->[?:ShootDay]]) == 2;
}

test "a day with no scenes gives an empty sheet" {
    w = root spawn CallSheet(day=9);
    assert len(w.reports) == 1;
    assert len(w.reports[0]) == 0;
    assert w.locations == 0;
}

test "call time is first scene minus department prep" {
    sc = add_scene(1, "12", 600, "Studio");
    assign(hire("Mo", Department.MAKEUP), sc);
    assign(hire("Wy", Department.WARDROBE), sc);
    assign(hire("Ca", Department.CAMERA), sc);
    assign(hire("Su", Department.SOUND), sc);
    w = root spawn CallSheet(day=1);
    assert w.reports[0] == ["08:00 Mo (MAKEUP)", "08:30 Wy (WARDROBE)", "09:00 Ca (CAMERA)", "09:30 Su (SOUND)"];
    assert w.locations == 1;
}

test "earliest scene of the day wins regardless of assignment order" {
    late = add_scene(2, "5B", 900, "Pier");
    early = add_scene(2, "5A", 500, "Pier");
    g = hire("Gil", Department.GRIP);
    assign(g, late);
    assign(g, early);
    assert (root spawn CallSheet(day=2)).reports[0] == ["07:50 Gil (GRIP)"];
}

test "scenes on other days are ignored" {
    other = add_scene(1, "1A", 200, "Barn");
    today = add_scene(3, "3A", 700, "Field");
    p = hire("Pat", Department.CAMERA);
    assign(p, other);
    assign(p, today);
    w = root spawn CallSheet(day=3);
    assert w.reports[0] == ["10:40 Pat (CAMERA)"];
    assert w.locations == 1;
}

test "each person appears once" {
    a = add_scene(6, "1", 600, "A");
    b = add_scene(6, "2", 660, "B");
    c = add_scene(6, "3", 720, "C");
    s = hire("Sam", Department.SOUND);
    assign(s, a);
    assign(s, b);
    assign(s, c);
    w = root spawn CallSheet(day=6);
    assert w.reports[0] == ["09:30 Sam (SOUND)"];
    assert w.locations == 3;
}

test "unassigned crew are not called" {
    add_scene(7, "1", 600, "A");
    hire("Idle", Department.CAMERA);
    assert len((root spawn CallSheet(day=7)).reports[0]) == 0;
}

test "sheet sorted by time then name and locations are distinct" {
    s1 = add_scene(8, "1", 600, "Roof");
    s2 = add_scene(8, "2", 690, "Alley");
    s3 = add_scene(8, "3", 800, "Roof");
    z = hire("Zoe", Department.GRIP);
    a = hire("Abe", Department.GRIP);
    w2 = hire("Wil", Department.WARDROBE);
    m = hire("Max", Department.MAKEUP);
    assign(z, s1);
    assign(a, s1);
    assign(w2, s2);
    assign(m, s3);
    w = root spawn CallSheet(day=8);
    assert w.reports[0] == ["09:30 Abe (GRIP)", "09:30 Zoe (GRIP)", "10:00 Wil (WARDROBE)", "11:20 Max (MAKEUP)"];
    assert w.locations == 2;
}
