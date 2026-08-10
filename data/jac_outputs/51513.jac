"""Check whether all pre-commit linter checks have passed."""
def all_checks_passed(linter_stdout: list[str]) -> bool {
    'All Checks Passed.' in linter_stdout[-1]
}