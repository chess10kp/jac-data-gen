"""Returns the total number of traces captured."""
def num_trace_events(data: dict[str, list]) -> int {
    return len(data["traceEvents"]);
}