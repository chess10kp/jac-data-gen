Hey — I run a small cleaning crew and track shifts as text like `09:15-12:30`. I'd like a Jac file `timesheet.jac` with a few functions so I can stop adding these up on paper:

1. `parse_span(span: str) -> int` — minutes in a span. `"09:15-12:30"` is 195. If the end is earlier than the start it crossed midnight (`"22:00-02:00"` is 240). Start equal to end is 0. Bad input (`"9-5"`, `"25:00-26:00"`, `"09:60-10:00"`, no dash) should raise `ValueError`. Hours are 00-23, minutes 00-59, always two digits each.
2. `day_minutes(spans: list[str]) -> int` — total minutes for a day's list of spans.
3. `format_hm(minutes: int) -> str` — like `"3h15m"`, minutes always two digits: `"0h05m"`, `"41h00m"`.
4. `weekly_pay(days: dict[str, list[str]], rate: float) -> float` — `days` maps a day name to its spans. Pay `rate` per hour for the first 40 hours of the week and 1.5× the rate for anything over 40. Round to cents.
