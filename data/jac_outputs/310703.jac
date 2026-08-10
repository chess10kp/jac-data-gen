"""Parse a multiline parameter string into a kwargs dictionary."""
def param_string_to_kwargs_dict(multiline_param_string: str) -> dict[str, str | int | float | bool] {
    params = [];
    param_vals = [];
    for (index, param) in enumerate(multiline_param_string.split("\n")) {
        if index == 0 or index % 2 == 0 {
            params.append(param.replace(":", ""));
        } else {
            parsed: str | int | float | bool = param;
            try {
                parsed = int(param) as str | int | float | bool;
            } except ValueError {
                try {
                    parsed = float(param) as str | int | float | bool;
                } except ValueError {
                    ;
                }
            }
            if parsed == 'True' {
                parsed = True;
            }
            if parsed == 'False' {
                parsed = False;
            }
            param_vals.append(parsed);
        }
    }
    return dict(zip(params, param_vals));
}