"""In some cases, we should filter out demonstrations.

Filter for if t == 0, which means the initial state was a success, and
also if we have exit_gracefully, which means for the bag-items tasks, it
may not have had visible item(s) at the start, for some reason.
"""
def ignore_this_demo(args: dict[str, str], reward: float, t: int, last_extras: dict[str, bool]) -> bool {
    ignore = t == 0;
    if 'exit_gracefully' in last_extras {
        assert last_extras['exit_gracefully'];
        return True;
    }
    return ignore;
}