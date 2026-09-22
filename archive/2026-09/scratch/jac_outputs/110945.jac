"""Checks the validity of the run_name. run_name cannot have spaces or colons."""
def is_valid_run_name(run_name: str) -> str | bool {
    return run_name and not (' ' in run_name or ':' in run_name);
}