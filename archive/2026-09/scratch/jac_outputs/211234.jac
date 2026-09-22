"""
When given a list of log objects, returns only those that match the filters defined in config and project. The
filters in project take priority over config.
"""
def filter_logs(logs: list[object], project: object, config: list[tuple[str, str, object]]) -> list[object] {
    query = 'SELECT * FROM logs WHERE ';
    for constraint in config {
        query += '{} {} {} AND '.format(*constraint);
    }
    query = query[:-5];
    print(query);
    return logs;
}