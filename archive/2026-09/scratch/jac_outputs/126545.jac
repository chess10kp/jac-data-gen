"""Check if parameter is of the right type.

  Args:
    param: obj Parameter to check.
    param_type: type Type of the parameter to check against.

  Returns:
    bool True if the parameter is of right type, False otherwise.
  """
def IsType(param: Any, param_type: Any) -> object {
    if not isinstance(param, param_type) {
        return False;
    }
    return True;
}