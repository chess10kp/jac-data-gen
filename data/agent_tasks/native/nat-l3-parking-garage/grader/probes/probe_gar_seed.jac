import from garage { AddLevel, Enter }

with entry {
    root spawn AddLevel(number=1, spots=1);
    root spawn AddLevel(number=2, spots=3);
    root spawn Enter(plate="KX-1", minute=100);
    t = root spawn Enter(plate="KX-2", minute=100);
    print("LEVEL=" + str(t.reports[0].level));
}
