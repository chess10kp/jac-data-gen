"""Gets the path to the logdog annotations."""
def _GetQueryParametersForAnnotation(log_location: str | None) -> tuple[str | None, str | None, str | None] {
    host = project = path = None;
    if log_location {
        (_, _, host, project, path) = log_location.split('/', 4);
    }
    return (host, project, path);
}