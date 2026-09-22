"""Execute all functions defined for an event of a parser.

If a function returns ``False``, this function will return ``True`` meaning
that an event is trying to skip the associated function.
"""
def raise_skip_event(events: dict[str, list], event_name: str, *event_args: str | int | float | bool | None) -> bool {
    try {
        pre_events = events[event_name];
    } except KeyError {
        return False;
    }
    should_skip = False;
    for event in pre_events {
        if event(*event_args) is False {
            should_skip = True;
        }
    }
    return should_skip;
}