import from contest { Band, LogQso }

test "lower case repeat is a dupe" {
    assert (root spawn LogQso(call="K1ABC", band=Band.B20M, minute=1, zone=5)).reports[0] == "ok";
    assert (root spawn LogQso(call="k1abc", band=Band.B20M, minute=9, zone=5)).reports[0] == "dupe";
}
