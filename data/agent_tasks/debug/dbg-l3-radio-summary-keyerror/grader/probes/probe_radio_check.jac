import from contest { Band, LogQso, Score }

with entry {
    d = root spawn LogQso(call="VE3AAA", band=Band.B40M, minute=60, zone=4);
    print("RELOG=" + d.reports[0]);
    s = root spawn Score();
    print("SCORE=" + str(s.reports[0]));
}
