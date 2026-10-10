import from greenhouse { PlantIn, WaterBed }

with entry {
    root spawn PlantIn(bed="N", species="fern", interval_days=3, day=1);
    root spawn PlantIn(bed="N", species="moss", interval_days=10, day=1);
    root spawn PlantIn(bed="S", species="cactus", interval_days=20, day=1);
    w = root spawn WaterBed(bed="N", day=4);
    print("SEEDED=" + str(w.reports[0]));
}
