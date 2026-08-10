"""Initialize time data."""
def init_time(p: dict[str, object], **kwargs: dict[str, object]) -> dict[str, object] {
    time_data = {'times': [p['parse']], 'slots': p['slots']};
    time_data.update(**kwargs);
    return time_data;
}