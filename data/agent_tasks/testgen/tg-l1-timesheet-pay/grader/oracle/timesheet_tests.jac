import from timesheet { parse_span, day_minutes, format_hm, weekly_pay }

test "parse spans" {
    assert parse_span("09:15-12:30") == 195;
    assert parse_span("22:00-02:00") == 240;
    assert parse_span("08:00-08:00") == 0;
    assert parse_span("00:00-23:59") == 1439;
}

test "parse rejects bad spans" {
    for bad in ["9-5", "25:00-26:00", "09:60-10:00", "0900", "09:00-", "ab:cd-ef:gh"] {
        with testraises(ValueError) {
            parse_span(bad);
        }
    }
}

test "day totals" {
    assert day_minutes(["09:00-12:00", "13:00-17:30"]) == 450;
    assert day_minutes([]) == 0;
}

test "format hours and minutes" {
    assert format_hm(195) == "3h15m";
    assert format_hm(5) == "0h05m";
    assert format_hm(2460) == "41h00m";
    assert format_hm(0) == "0h00m";
}

test "weekly pay with overtime" {
    week = {
        "mon": ["08:00-17:00"], "tue": ["08:00-17:00"], "wed": ["08:00-17:00"],
        "thu": ["08:00-17:00"], "fri": ["08:00-14:00"]
    };
    # 9*4 + 6 = 42 hours -> 40*20 + 2*30
    assert abs(weekly_pay(week, 20.0) - 860.0) < 1e-6;
    assert abs(weekly_pay({"sat": ["10:00-12:30"]}, 18.5) - 46.25) < 1e-6;
    assert abs(weekly_pay({}, 18.5)) < 1e-6;
}
