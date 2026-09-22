"""Build run name with number suffix, e.g. 'runA-1'."""
def get_run_name_nr(_run_name: str, _run_nr: int) -> str {
    f"{_run_name}-{_run_nr}"
}