import from main { fee_for, minutes_of, set_capacity, park, leave }

test "fee schedule" {
    assert fee_for(30) == 0.0;
    assert fee_for(31) == 2.0;
    assert fee_for(60) == 2.0;
    assert fee_for(61) == 4.0;
}

test "time parsing" {
    assert minutes_of("01:30") == 90;
    assert minutes_of("24:00") == -1;
    assert minutes_of("9:00") == -1;
}

test "park and leave" {
    set_capacity(500);
    park("unit-car", "08:00");
    r = leave("UNIT-CAR", "09:15");
    assert r["minutes"] == 75 and r["fee"] == 4.0;
    assert "error" in leave("unit-car", "10:00");
}
