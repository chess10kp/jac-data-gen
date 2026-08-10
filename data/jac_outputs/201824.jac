"""Describe the result from "import-results"."""
def describe_result(result: dict[str, str]) -> str {
    status = result['status'];
    suite_name = result['suite-name'];
    return '%s %s' % (status, suite_name);
}