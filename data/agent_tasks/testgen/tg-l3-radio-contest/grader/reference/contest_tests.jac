import from contest { Band, BandLog, Qso, Logged, LogQso, Score, BandSummary }

def log(call: str, band: Band, minute: int, zone: int) -> str {
    w = root spawn LogQso(call=call, band=band, minute=minute, zone=zone);
    assert len(w.reports) == 1;
    return w.reports[0];
}

test "nothing logged scores zero" {
    w = root spawn Score();
    assert len(w.reports) == 1;
    assert w.reports[0] == 0;
    assert w.qsos == 0;
    assert w.mults == 0;
}

test "first contact creates a band log and stores the qso upper-cased" {
    assert log("g4xyz", Band.B40M, 12, 14) == "ok";
    logs = [root -->[?:BandLog]];
    assert len(logs) == 1;
    assert logs[0].band == Band.B40M;
    qs = [logs[0] ->:Logged:->];
    assert len(qs) == 1;
    assert qs[0].call == "G4XYZ";
    assert qs[0].minute == 12;
    assert qs[0].zone == 14;
}

test "one band log per band" {
    log("A1", Band.B20M, 1, 1);
    log("B2", Band.B20M, 2, 1);
    log("C3", Band.B80M, 3, 1);
    assert len([root -->[?:BandLog]]) == 2;
}

test "same call on the same band is a dupe regardless of case" {
    assert log("ON4UN", Band.B10M, 1, 14) == "ok";
    assert log("on4un", Band.B10M, 2, 14) == "dupe";
    assert log("ON4UN", Band.B10M, 3, 14) == "dupe";
    book = [root -->[?:BandLog]][0];
    assert len([book ->:Logged:->]) == 1;
}

test "same call on another band is fine" {
    assert log("ON4UN", Band.B10M, 1, 14) == "ok";
    assert log("ON4UN", Band.B20M, 2, 14) == "ok";
    assert log("ON4UN", Band.B40M, 3, 14) == "ok";
}

test "score is qsos times distinct zones" {
    log("A", Band.B20M, 1, 5);
    log("B", Band.B20M, 2, 5);
    log("C", Band.B20M, 3, 8);
    w = root spawn Score();
    assert w.qsos == 3;
    assert w.mults == 2;
    assert w.reports[0] == 6;
}

test "zones are counted once across bands and dupes do not score" {
    log("A", Band.B20M, 1, 5);
    log("A", Band.B40M, 2, 5);
    log("B", Band.B80M, 3, 33);
    log("b", Band.B80M, 4, 40);
    log("C", Band.B10M, 5, 3);
    w = root spawn Score();
    assert w.qsos == 4;
    assert w.mults == 3;
    assert w.reports[0] == 12;
}

test "band summary covers only bands that were used" {
    log("A", Band.B40M, 1, 1);
    log("B", Band.B40M, 2, 1);
    log("C", Band.B40M, 3, 1);
    log("A", Band.B80M, 4, 1);
    w = root spawn BandSummary();
    assert len(w.reports) == 1;
    assert w.reports[0] == {"B40M": 3, "B80M": 1};
}

test "band summary of an empty log is empty" {
    w = root spawn BandSummary();
    assert len(w.reports[0]) == 0;
}
