"""Validate a boolean parameter and return its fixed string form."""
def verify_bool_parameter(bool_param: bool | None) -> str | None {
    match bool_param {
        case None:
            return None;
        case True:
            return "true";
        case False:
            return "false";
        case _:
            raise ValueError(
                '"{}" is not a valid parameter. Allowed values are: True or False'.format(
                    bool_param
                )
            );
    }
}