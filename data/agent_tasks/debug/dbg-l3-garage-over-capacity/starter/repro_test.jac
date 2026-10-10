import from garage { AddLevel, Enter, Occupancy }

test "full level sends the next car upstairs" {
    root spawn AddLevel(number=1, spots=1);
    root spawn AddLevel(number=2, spots=1);
    assert (root spawn Enter(plate="A", minute=0)).reports[0].level == 1;
    assert (root spawn Enter(plate="B", minute=0)).reports[0].level == 2;
    assert (root spawn Enter(plate="C", minute=0)).reports[0].reason == "full";
}
