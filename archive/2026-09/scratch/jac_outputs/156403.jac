"""Parse command line arguments into positional parameters, options and flags."""
def parse_arguments(arguments: list[str]) -> tuple[list[str], dict[str, str], list[str]] {
    positional_arguments = [];
    option_values = {};
    flag_values = [];
    for arg in arguments {
        if arg[0] != '-' {
            positional_arguments.append(arg);
        } elif '=' in arg {
            pair = arg.split('=');
            if pair[0][1] == '-' {
                option_values[pair[0][2:]] = pair[1];
            } else {
                option_values[pair[0][1]] = pair[1];
            }
        } elif arg[1] == '-' {
            flag_values.append(arg[2:]);
        } else {
            flag_values.append(arg[1:]);
        }
    }
    return (positional_arguments, option_values, flag_values);
}