"""Convert bytes to KB, MB, GB, and TB representations."""
def convert_bytes(num: float) -> list[str] {
    step_unit = 1000.0;
    results = [];
    for unit in ['bytes', 'KB', 'MB', 'GB', 'TB'] {
        results.append("%3.2f %s" % (num, unit));
        num /= step_unit;
    }
    return results;
}