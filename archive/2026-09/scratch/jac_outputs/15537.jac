"""Concerts an instruction trace into a string."""
def itraceToStr(trace: list[tuple | list]) -> str {
    trace_str = "";
    for i in trace {
        trace_str += "%s," % i[0];
    }
    return trace_str[:-1];
}