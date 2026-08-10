"""Formats slack message using slack emojis."""
def format_slack_message(
    table_name: str,
    metric: str,
    avg_time: float,
    increase: float | None,
    stddev: float,
    stddev_old: float
) -> str {
    table_name_formatted = '`{}`'.format(table_name);
    if increase is None {
        increase_formatted = "NA";
    } elif increase >= 0 {
        increase_formatted = '`{:+.3f}%` :-1:'.format(increase);
    } else {
        increase_formatted = '*{:+.3f}%* :+1:'.format(increase);
    }
    stddev_formatted = '*{:.2f}*'.format(stddev);
    stddev_old_formatted = '*{:.2f}*'.format(stddev_old);
    return '{} - "{}", avg_time {:.2f}s, change {}, stddev {}, stddev_old {} \n'.format(
        table_name_formatted,
        metric,
        avg_time,
        increase_formatted,
        stddev_formatted,
        stddev_old_formatted
    );
}