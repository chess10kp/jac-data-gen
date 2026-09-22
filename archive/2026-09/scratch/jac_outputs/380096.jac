"""Return whether the demo should continue to run."""
def running(demo_mode: bool, step: int, max_step: int) -> bool {
    if demo_mode {
        return True;
    }
    return step <= max_step;
}