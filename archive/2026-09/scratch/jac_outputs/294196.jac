"""Sort events by thread names"""
def sorted_keys(grouped_events: dict[str, object]) -> list[str] {
    keys = list(grouped_events.keys());
    keys = sorted(keys, key=lambda (s: str) { s.split('|')[-1]; });
    return list(reversed(keys));
}