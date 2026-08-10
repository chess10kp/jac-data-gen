"""
    Get a data structure for showing a sorted list of variables from the
    request data.
    """
def get_sorted_request_variable(variable: Any) -> object {
    try {
        if isinstance(variable, `dict) {
            return {"list": [(k, variable.get(k)) for k in sorted(variable)]};
        } else {
            return {"list": [(k, variable.getlist(k)) for k in sorted(variable)]};
        }
    } except TypeError {
        return {"raw": variable};
    }
}