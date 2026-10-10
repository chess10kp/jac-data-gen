"""Shift span arithmetic and weekly pay."""

def parse_clock(t: str) -> int {
    if len(t) != 5 or t[2] != ":" or not t[:2].isdigit() or not t[3:].isdigit() {
        raise ValueError(f"bad time {t}");
    }
    h = int(t[:2]);
    m = int(t[3:]);
    if h > 23 or m > 59 {
        raise ValueError(f"bad time {t}");
    }
    return h * 60 + m;
}

def parse_span(span: str) -> int {
    parts = span.strip().split("-");
    if len(parts) != 2 {
        raise ValueError(f"bad span {span}");
    }
    start = parse_clock(parts[0].strip());
    end = parse_clock(parts[1].strip());
    if end < start {
        end += 24 * 60;
    }
    return end - start;
}

def day_minutes(spans: list[str]) -> int {
    return sum([parse_span(s) for s in spans]);
}

def format_hm(minutes: int) -> str {
    return f"{minutes // 60}h{minutes % 60:02d}m";
}

def weekly_pay(days: dict[str, list[str]], rate: float) -> float {
    total = sum([day_minutes(spans) for spans in days.values()]);
    hours = total / 60;
    regular = min(hours, 40.0);
    overtime = max(0.0, hours - 40.0);
    return round(regular * rate + overtime * rate * 1.5, 2);
}
