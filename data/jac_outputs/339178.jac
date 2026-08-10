"""Check the results list for any possible error and return a tuple which
    contains the status and error message."""
def result_has_error(results: list[dict[str, str]]) -> tuple[bool, bool, str] {
    for result in results {
        if 'stat' not in result {
            return (True, False, "Unexpected API response");
        } elif result['stat'] == "error" {
            return (False, True, result['error_description']);
        }
    }
    return (False, False, "");
}