""" Transform a dictionary into a list of command arguments.
  Args:
    dp Dictionary mapping parameter name (to prepend with "--") to parameter value (to convert to string)
  Returns:
    Associated list of command arguments
  Notes:
    For entries mapping to 'bool', the parameter is included/discarded depending on whether the value is True/False
    For entries mapping to 'list' or 'tuple', the parameter is followed by all the values as strings
  """
def dict_to_cmdlist(dp: Any) -> object {
    cmd = `list();
    for (name, value) in dp.items() {
        if isinstance(value, bool) {
            if value {
                cmd.append(f"--{name}");
            }
        } elif `any(isinstance(value, typ) for typ in (`list, `tuple)) {
            cmd.append(f"--{name}");
            for subval in value {
                cmd.append(str(subval));
            }
        } elif (value is not None) {
            cmd.append(f"--{name}");
            cmd.append(str(value));
        }
    }
    return cmd;
}