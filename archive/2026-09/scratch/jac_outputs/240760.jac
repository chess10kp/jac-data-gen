"""Parse the scenarios and feed the IDs to the test function."""
def scenario_ids(scenarios: Any) -> object {
    return [test_input[1] for test_input in scenarios];
}