"""If there are any stacks not in a steady state, don't cache."""
def _no_pending_stacks(stacks: list[dict[str, str]]) -> bool {
    for stack in stacks {
        status = stack['stack_status'];
        if '_COMPLETE' not in status and '_FAILED' not in status {
            return False;
        }
    }
    return True;
}