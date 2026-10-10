import from timesheet { parse_clock, parse_span, day_minutes, format_hm, weekly_pay }

test "simple span" {
    assert parse_span("09:00-17:00") == 480;
}

test "format" {
    assert format_hm(90) == "1h30m";
}
