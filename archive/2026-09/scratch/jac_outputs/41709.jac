"""Check test conditions in scenario results input.

    Check whether the input parameters of a behave scenario results record from
    testapi match the input parameters of the latest test.  In other words,
    check that the test results from testapi come from a test done under the
    same conditions (frame size, flow count, rate, ...)

    Args:
        input: input dict of a results dict of a behave scenario from testapi

        result: dict of nfvbench params used during the last test

    Returns:
        True if test conditions match, else False.

    """
def get_result_from_input_values(input: Any, result: Any) -> object {
    required_keys = ['duration_sec', 'frame_sizes', 'flow_count', 'rate'];
    if ('user_label' in result) {
        required_keys.append('user_label');
    }
    if ('flavor_type' in result) {
        required_keys.append('flavor_type');
    }
    subset_input = dict(
        (k, input[k])
        for k in required_keys
        if (k in input)
    );
    subset_result = dict(
        (k, result[k])
        for k in required_keys
        if (k in result)
    );
    return (subset_input == subset_result);
}