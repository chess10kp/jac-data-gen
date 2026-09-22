"""Truncates a string of a given length, adds three dots at the end."""
def truncate(value: str, arg: int) -> str | None {
    try {
        if len(value) > arg {
            return f"{value[0:arg - 3]}...";
        }
        return value;
    } except ValueError {
        ;
    }
}