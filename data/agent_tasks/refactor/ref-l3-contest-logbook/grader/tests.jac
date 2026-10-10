import from logbook { Logbook }

def sample -> Logbook {
    lb = Logbook(callsign="K1ABC");
    lb.log("w1aw", "20m", 5, 5);
    lb.log("DL1XX", "20m", 12, 14);
    lb.log("W1AW", "40m", 30, 5);
    lb.log("ja1zz", "10m", 31, 25);
    lb.log("VE3QQ", "40m", 44, 4);
    lb.log("g4abc", "20m", 60, 14);
    return lb;
}

test "logging, dupes and bad bands" {
    lb = Logbook(callsign="K1ABC");
    assert lb.log("w1aw", "20m", 1, 5) == "ok";
    assert lb.log("W1AW", "20m", 2, 5) == "dupe";
    assert lb.log("W1aw", "40m", 3, 5) == "ok";
    assert lb.log("W1AW", "15m", 4, 5) == "bad band";
    assert lb.log("N0CALL", "2m", 4, 5) == "bad band";
    assert lb.band_counts() == ["40m:1", "20m:1"];
}

test "score is contacts times distinct zones" {
    lb = Logbook(callsign="K1ABC");
    assert lb.score() == 0;
    lb = sample();
    assert lb.score() == 24;
    lb.log("W1AW", "20m", 70, 5);
    assert lb.score() == 24;
    lb.log("W1AW", "80m", 70, 5);
    assert lb.score() == 28;
}

test "band counts in band order" {
    lb = sample();
    assert lb.band_counts() == ["40m:2", "20m:3", "10m:1"];
    lb.log("k2xyz", "80m", 90, 5);
    assert lb.band_counts() == ["80m:1", "40m:2", "20m:3", "10m:1"];
}

test "which bands a station was worked on" {
    lb = sample();
    assert lb.worked_on("w1aw") == ["40m", "20m"];
    assert lb.worked_on("JA1ZZ") == ["10m"];
    assert len(lb.worked_on("N0PE")) == 0;
}

test "busiest zone and time windows" {
    lb = Logbook(callsign="K1ABC");
    assert lb.busiest_zone() == -1;
    lb = sample();
    assert lb.busiest_zone() == 5;
    lb.log("ZZ9ZZ", "10m", 61, 4);
    assert lb.busiest_zone() == 4;
    assert lb.in_window(0, 30) == 2;
    assert lb.in_window(30, 61) == 4;
    assert lb.in_window(5, 6) == 1;
    assert lb.in_window(100, 200) == 0;
}

test "logbooks are independent" {
    a = sample();
    b = Logbook(callsign="N2XYZ");
    assert b.log("W1AW", "20m", 1, 5) == "ok";
    assert b.score() == 1;
    assert b.band_counts() == ["20m:1"];
    assert a.worked_on("W1AW") == ["40m", "20m"];
    assert a.score() == 24;
}
