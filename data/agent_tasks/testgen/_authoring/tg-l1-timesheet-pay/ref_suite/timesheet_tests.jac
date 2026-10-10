import from timesheet { parse_clock, parse_span, day_minutes, format_hm, weekly_pay }

test "simple span" {
    assert parse_span("09:00-17:00") == 480;
}

test "format" {
    assert format_hm(90) == "1h30m";
}

test "parse_clock" {
    assert parse_clock("00:00") == 0;
    assert parse_clock("23:59") == 1439;
    assert parse_clock("07:05") == 425;
    assert parse_clock("12:00") == 720;
}

test "parse_clock rejects malformed times" {
    for bad in ["24:00", "12:60", "7:05", "07-05", "0705", "aa:bb", "07:5", "007:05"] {
        try {
            parse_clock(bad);
            assert False, "expected ValueError";
        } except ValueError {
            assert True;
        }
    }
}

test "spans including whitespace and overnight" {
    assert parse_span(" 09:30 - 10:00 ") == 30;
    assert parse_span("23:00-01:30") == 150;
    assert parse_span("10:00-10:00") == 0;
    assert parse_span("10:01-10:00") == 1439;
}

test "parse_span rejects malformed spans" {
    for bad in ["09:00", "09:00-10:00-11:00", "09:00-", "x-y"] {
        try {
            parse_span(bad);
            assert False, "expected ValueError";
        } except ValueError {
            assert True;
        }
    }
}

test "day totals" {
    assert day_minutes(["08:00-12:00", "12:30-17:00"]) == 510;
    assert day_minutes(["22:00-02:00"]) == 240;
    assert day_minutes([]) == 0;
}

test "format pads minutes" {
    assert format_hm(0) == "0h00m";
    assert format_hm(59) == "0h59m";
    assert format_hm(60) == "1h00m";
    assert format_hm(605) == "10h05m";
}

test "pay without overtime" {
    week = {"mon": ["09:00-17:00"], "tue": ["09:00-17:00"]};
    assert weekly_pay(week, 20.0) == 320.0;
    assert weekly_pay({}, 20.0) == 0.0;
}

test "exactly forty hours has no overtime" {
    week = {"mon": ["08:00-16:00"], "tue": ["08:00-16:00"], "wed": ["08:00-16:00"], "thu": ["08:00-16:00"], "fri": ["08:00-16:00"]};
    assert weekly_pay(week, 10.0) == 400.0;
}

test "overtime at time and a half" {
    week = {"mon": ["08:00-18:00"], "tue": ["08:00-18:00"], "wed": ["08:00-18:00"], "thu": ["08:00-18:00"], "fri": ["08:00-12:30"]};
    assert weekly_pay(week, 10.0) == 467.5;
}

test "pay is rounded to cents" {
    assert weekly_pay({"mon": ["09:00-09:20"]}, 10.0) == 3.33;
}
