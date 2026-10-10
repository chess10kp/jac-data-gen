import from shelves { add_shelf, place_piece, shelf_load, shelves_holding, collect, free_slots }

test "shelves are unique by name" {
    assert add_shelf("north", 3);
    assert not add_shelf("north", 9);
    assert add_shelf("kiln-side", 2);
    assert free_slots() == 5;
}

test "placing respects capacity and unknown shelves" {
    add_shelf("north", 2);
    assert place_piece("north", "ines", 1.5);
    assert place_piece("north", "tom", 0.75);
    assert not place_piece("north", "ines", 2.0);
    assert not place_piece("south", "ines", 2.0);
    assert shelf_load("north") == 2.25;
    assert shelf_load("south") == 0.0;
    assert free_slots() == 0;
}

test "which shelves hold a maker's work" {
    add_shelf("b", 4);
    add_shelf("a", 4);
    add_shelf("c", 4);
    place_piece("b", "ines", 1.0);
    place_piece("a", "ines", 1.0);
    place_piece("a", "ines", 2.0);
    place_piece("c", "tom", 1.0);
    assert shelves_holding("ines") == ["a", "b"];
    assert shelves_holding("tom") == ["c"];
    assert len(shelves_holding("ana")) == 0;
}

test "collecting frees slots and only takes that maker's pieces" {
    add_shelf("a", 3);
    add_shelf("b", 3);
    place_piece("a", "ines", 1.0);
    place_piece("a", "tom", 2.0);
    place_piece("b", "ines", 4.0);
    place_piece("b", "ines", 0.5);
    assert collect("ines") == 3;
    assert collect("ines") == 0;
    assert shelf_load("a") == 2.0;
    assert shelf_load("b") == 0.0;
    assert free_slots() == 5;
    assert shelves_holding("tom") == ["a"];
    assert len(shelves_holding("ines")) == 0;
    assert place_piece("b", "ana", 1.0);
}
