import from greenhouse { PlantIn, WaterBed, DueOn }

test "watering one bed leaves the others due" {
    root spawn PlantIn(bed="B1", species="basil", interval_days=2, day=0);
    root spawn PlantIn(bed="B2", species="thyme", interval_days=2, day=0);
    assert (root spawn WaterBed(bed="B1", day=3)).reports[0] == 1;
    assert (root spawn DueOn(day=4)).reports[0] == ["B2/thyme"];
}
