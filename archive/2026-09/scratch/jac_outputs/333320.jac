"""
Get parameters from a process, if they are in its definition.
"""
def get_process_params(
    process_args: dict[str, str | int | dict[str, str]],
    param_dict: dict[str, str | list[str]]
) -> dict[str, str | list[str]] {
    process_params: dict[str, str | list[str]] = {};
    for param in param_dict {
        if param in process_args {
            if (
                param in ('y', 'mask')
                and isinstance(process_args[param], dict)
                and 'from_node' in process_args[param]
            ) {
                process_params[param] = 'set' + (param_dict[param] as str) + ';str';
            } elif isinstance(param_dict[param], list) {
                param_spec = param_dict[param] as list[str];
                process_params[param_spec[0]] = (
                    str(process_args[param]) + ';' + param_spec[1]
                );
            } else {
                process_params[param] = (
                    str(process_args[param]) + ';' + (param_dict[param] as str)
                );
            }
        } elif param == 'extra_values' {
            process_params[param] = param_dict[param];
        }
    }
    return process_params;
}