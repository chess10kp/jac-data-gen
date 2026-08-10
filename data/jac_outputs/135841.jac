"""
    @cmd_list - List of cmd args.
    @param_name - Param name / flag.
    @param_value - Value of the parameter
    @is_bool - Flag is a boolean and has no value.
    """
def add_arg_to_cmd(
    cmd_list: Any, param_name: Any, param_value: Any, is_bool: Any = False
) -> object {
    if ((is_bool is False) and (param_value is not None)) {
        cmd_list.append(param_name);
        if (param_name == "--eval") {
            cmd_list.append("\"{0}\"".format(param_value));
        } else {
            cmd_list.append(param_value);
        }
    } elif (is_bool is True) {
        cmd_list.append(param_name);
    }
    return cmd_list;
}