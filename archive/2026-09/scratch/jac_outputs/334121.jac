"""Check for the correct format of string timestamp with format <date>_<time>."""
def check_valid_timestamp(timestamp: str | None = None) -> bool {
    ts_valid = False;
    if timestamp is not None {
        parts = timestamp.split("_");
        if len(parts) == 2 and len(parts[0]) == 6 and len(parts[1]) == 4 {
            ts_valid = True;
        }
    }
    return ts_valid;
}