import from callsheet { hire, add_scene, assign, call_sheet, locations, crew_days, idle }

def crew_up {
    hire("Ola", "makeup");
    hire("Raj", "camera");
    hire("Sue", "sound");
    hire("Tom", "grip");
    hire("Vic", "wardrobe");
}

test "hiring rejects duplicates and unknown departments" {
    assert hire("Ola", "makeup");
    assert not hire("Ola", "camera");
    assert not hire("Pip", "catering");
    assert hire("Pip", "grip");
    assert idle("grip") == ["Pip"];
    assert idle("makeup") == ["Ola"];
    assert len(idle("sound")) == 0;
}

test "scenes and assignments validate their inputs" {
    crew_up();
    assert add_scene(1, "12A", "09:00", "Diner");
    assert not add_scene(2, "12A", "10:00", "Pier");
    assert assign("Raj", "12A");
    assert not assign("Raj", "12A", 15);
    assert not assign("Zed", "12A");
    assert not assign("Raj", "99");
    assert len(idle("camera")) == 0;
    assert idle("grip") == ["Tom"];
}

test "call times use department prep and the earliest scene" {
    crew_up();
    add_scene(1, "4", "10:30", "Diner");
    add_scene(1, "5", "08:00", "Diner");
    add_scene(1, "7", "13:00", "Pier");
    assign("Ola", "4");
    assign("Raj", "4");
    assign("Raj", "7");
    assign("Sue", "7");
    assign("Vic", "5");
    assign("Tom", "4");
    assert call_sheet(1) == [
        "06:30 Vic (WARDROBE)",
        "08:30 Ola (MAKEUP)",
        "09:30 Raj (CAMERA)",
        "10:00 Tom (GRIP)",
        "12:30 Sue (SOUND)"
    ];
}

test "extra early minutes and ties sort by name" {
    crew_up();
    hire("Ana", "sound");
    add_scene(3, "20", "11:00", "Barn");
    assign("Sue", "20");
    assign("Ana", "20");
    assign("Tom", "20", 15);
    assign("Raj", "20", 5);
    assert call_sheet(3) == [
        "09:55 Raj (CAMERA)",
        "10:15 Tom (GRIP)",
        "10:30 Ana (SOUND)",
        "10:30 Sue (SOUND)"
    ];
    assert len(call_sheet(4)) == 0;
}

test "days are kept apart" {
    crew_up();
    add_scene(1, "1", "09:00", "Diner");
    add_scene(2, "2", "07:00", "Pier");
    add_scene(2, "3", "09:00", "Diner");
    add_scene(2, "6", "12:00", "Pier");
    assign("Raj", "1");
    assign("Raj", "2");
    assign("Sue", "6");
    assert call_sheet(1) == ["08:00 Raj (CAMERA)"];
    assert call_sheet(2) == ["06:00 Raj (CAMERA)", "11:30 Sue (SOUND)"];
    assert locations(2) == ["Diner", "Pier"];
    assert locations(1) == ["Diner"];
    assert len(locations(5)) == 0;
}

test "days per crew member" {
    crew_up();
    add_scene(3, "a", "09:00", "Loft");
    add_scene(1, "b", "09:00", "Loft");
    add_scene(3, "c", "14:00", "Roof");
    add_scene(2, "d", "09:00", "Roof");
    assign("Sue", "a");
    assign("Sue", "c");
    assign("Sue", "b");
    assign("Tom", "d");
    assert crew_days("Sue") == [1, 3];
    assert crew_days("Tom") == [2];
    assert len(crew_days("Ola")) == 0;
    assert len(crew_days("Nobody")) == 0;
}
