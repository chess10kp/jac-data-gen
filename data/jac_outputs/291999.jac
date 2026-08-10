""" (list, fn) -> list

    Takes a list of events as well as a function that is called on each event.
    A list is returned, which is composed of the return values from the
    function.
    """
def process_events(events: list[str | int], fn: Callable[[str | int], str | int]) -> list[str | int] {
    return [fn(event) for event in events];
}