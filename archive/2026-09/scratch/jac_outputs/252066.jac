"""generates the bad query summary"""
def get_bad_query_summary(queries_above_threshold: list[str], total: int) -> str {
    total_suspect = len(queries_above_threshold);
    percent = 0.0;
    if total_suspect > 0 {
        percent = (float(total_suspect) / float(total)) * 100.0;
    }
    return "\nsuspect queries totals: %i/%i - %.2f%%\n" % (total_suspect, total, percent);
}