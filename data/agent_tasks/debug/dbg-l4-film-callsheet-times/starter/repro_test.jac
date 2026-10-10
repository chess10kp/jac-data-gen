import from crew { Department }
import from schedule { add_scene, hire, assign }
import from callsheet { CallSheet }

test "call time comes from the earliest scene" {
    s1 = add_scene(3, "4A", 540, "Diner");
    s2 = add_scene(3, "4B", 420, "Diner");
    mia = hire("Mia", Department.MAKEUP);
    assign(mia, s1);
    assign(mia, s2);
    w = root spawn CallSheet(day=3);
    assert w.reports[0] == ["05:00 Mia (MAKEUP)"];
    assert w.locations == 1;
}
