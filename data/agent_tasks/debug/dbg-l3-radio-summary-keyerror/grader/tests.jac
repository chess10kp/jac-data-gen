import from contest { Band, BandLog, Qso, Logged, LogQso, Score, BandSummary }

def qso(call: str, band: Band, minute: int, zone: int) -> str {
    return (root spawn LogQso(call=call, band=band, minute=minute, zone=zone)).reports[0];
}

test "empty log scores zero" {
    w = root spawn Score();
    assert w.reports[0] == 0;
    assert w.qsos == 0;
    assert w.mults == 0;
}

test "contacts are stored upper case under one band log" {
    assert qso("k1abc", Band.B20M, 1, 5) == "ok";
    assert qso("W9XYZ", Band.B20M, 2, 4) == "ok";
    logs = [root -->[?:BandLog]];
    assert len(logs) == 1;
    assert sorted([q.call for q in [logs[0] ->:Logged:->]]) == ["K1ABC", "W9XYZ"];
}

test "dupe is per band and case insensitive" {
    assert qso("K1ABC", Band.B20M, 1, 5) == "ok";
    assert qso("k1abc", Band.B20M, 9, 5) == "dupe";
    assert qso("K1ABC", Band.B40M, 10, 5) == "ok";
    assert len([root -->[?:BandLog]]) == 2;
}

test "score multiplies qsos by distinct zones across bands" {
    qso("A1A", Band.B20M, 1, 3);
    qso("B1B", Band.B20M, 2, 3);
    qso("C1C", Band.B40M, 3, 3);
    qso("D1D", Band.B40M, 4, 14);
    qso("D1D", Band.B40M, 5, 14);
    w = root spawn Score();
    assert w.qsos == 4;
    assert w.mults == 2;
    assert w.reports[0] == 8;
}

test "band summary counts per existing band log" {
    qso("A1A", Band.B80M, 1, 1);
    qso("B1B", Band.B80M, 2, 1);
    qso("A1A", Band.B10M, 3, 1);
    qso("A1A", Band.B10M, 4, 1);
    w = root spawn BandSummary();
    assert w.reports[0] == {"B80M": 2, "B10M": 1};
}
