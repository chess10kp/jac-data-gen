"""Concat the supplied parameters and return them in trace format."""
def message(
    operation: str,
    `type: str,
    resource: str,
    raw_resource: str,
    execution_time: str,
    status: str
) -> str {
    return "%s|%s|%s|%s|%s|%s" % (operation, `type, resource, raw_resource, execution_time, status);
}