"""Date and deadline utility functions."""

import from datetime { datetime, timedelta, date }

"""Return days until a date string. Negative = overdue."""
def days_until(date_str: str, fmt: str = "%Y-%m-%d") -> int {
    try {
        dt = datetime.strptime(date_str, fmt);
        return (dt - datetime.utcnow()).days;
    } except Exception {
        return 0;
    }
}

"""Return True if the date has passed."""
def is_overdue(date_str: str, fmt: str = "%Y-%m-%d") -> bool {
    return days_until(date_str, fmt) < 0;
}

"""Add N business days to a date, skipping weekends."""
def add_business_days(start_date: str, num_days: int, fmt: str = "%Y-%m-%d") -> str {
    try {
        dt = datetime.strptime(start_date, fmt);
        added = 0;
        while added < num_days {
            dt = dt + timedelta(days=1);
            if dt.weekday() < 5 {  # Mon-Fri
                added += 1;
            }
        }
        return dt.strftime(fmt);
    } except Exception {
        return start_date;
    }
}

"""Convert a date string to human-readable format (e.g., 'April 15, 2026')."""
def format_date_human(date_str: str, fmt: str = "%Y-%m-%d") -> str {
    try {
        dt = datetime.strptime(date_str, fmt);
        return dt.strftime("%B %-d, %Y");
    } except Exception {
        return date_str;
    }
}

"""
Calculate Medicare appeal deadline from service date.
Level 1 (Redetermination): 120 days from NOD
Level 2 (QIC): 180 days from redetermination decision
Level 3 (ALJ): 60 days from QIC decision
"""
def calc_appeal_deadline(service_date: str, appeal_level: int) -> str {
    deadline_map = {1: 120, 2: 180, 3: 60, 4: 60, 5: 60};
    days = deadline_map.get(appeal_level, 120);
    try {
        dt = datetime.strptime(service_date, "%Y-%m-%d");
        deadline = dt + timedelta(days=days);
        return deadline.strftime("%Y-%m-%d");
    } except Exception {
        return "";
    }
}

"""
Try multiple date formats and return ISO format (YYYY-MM-DD).
Returns empty string on failure.
"""
def parse_date_flexible(date_str: str) -> str {
    formats = [
        "%Y-%m-%d", "%m/%d/%Y", "%m-%d-%Y", "%d/%m/%Y",
        "%B %d, %Y", "%b %d, %Y", "%Y%m%d"
    ];
    for fmt in formats {
        try {
            dt = datetime.strptime(date_str.strip(), fmt);
            return dt.strftime("%Y-%m-%d");
        } except Exception {
            continue;
        }
    }
    return "";
}
