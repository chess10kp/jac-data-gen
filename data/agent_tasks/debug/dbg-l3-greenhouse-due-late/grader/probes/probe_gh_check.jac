import from greenhouse { DueOn, PlantIn }

with entry {
    d = root spawn DueOn(day=7);
    print("DUE=" + ",".join(d.reports[0]));
    again = root spawn PlantIn(bed="N", species="ivy", interval_days=1, day=7);
    print("BEDCOUNT=" + str(again.reports[0]));
}
