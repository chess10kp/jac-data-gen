"""
        Get the pattern attribute from either the current testdata block
        or from the global section
    """
def _get_pattern_list(
    testdata: Any, global_obj: Any, pattern: Any = "start"
) -> object {
    global_var_pattern = global_obj.find("variable_pattern")
        if (global_obj is not None)
        else None;
    if (pattern == "start") {
        resultant = "${";
    } else {
        resultant = "}";
    }
    if (testdata.get((pattern + "_pattern")) is not None) {
        resultant = testdata.get((pattern + "_pattern"));
    } elif (
        (global_var_pattern is not None)
        and (global_var_pattern.get((pattern + "_pattern")) is not None)
    ) {
        resultant = global_var_pattern.get((pattern + "_pattern"));
    }
    return resultant;
}