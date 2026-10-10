import from contest { Band, LogQso }

with entry {
    root spawn LogQso(call="ve3aaa", band=Band.B40M, minute=1, zone=4);
    root spawn LogQso(call="JA1BBB", band=Band.B40M, minute=2, zone=25);
    print("SEEDED");
}
