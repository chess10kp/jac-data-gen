"""Return bool list with a True item for each output matching expected output.
       Return None if the functions suspects user tried to print something when
       they should not have.
"""
def check_for_output_match(output: str, test_suite: list[dict[str, str]]) -> list[bool] | None {
    output_lines = output.splitlines();
    if len(output_lines) != len(test_suite) {
        return None;
    }
    result = [];
    for (exe_output, test_case) in zip(output_lines, test_suite) {
        prefix = "RESULT: ";
        if not exe_output.startswith(prefix) {
            return None;
        }
        exe_value = exe_output[len(prefix):];
        result.append(test_case['output'] == exe_value);
    }
    return result;
}