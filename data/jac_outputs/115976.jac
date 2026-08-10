"""
appends the given argument to a command line such that CommandLineToArgvW will return
the argument string unchanged.
"""
def win_concat_quote(command_line: str, argument: str) -> str {
    result = (command_line + " ") if command_line else "";
    if argument {
        if len(argument.split()) == 1 {
            if '"' not in argument {
                result += argument;
                return result;
            }
        }
    }
    result += '"';
    it = 0;
    end = len(argument);
    while it < end {
        number_backslashes = 0;
        char = argument[it];
        while char == '\\' {
            it += 1;
            number_backslashes += 1;
            try {
                char = argument[it];
            } except IndexError {
                break;
            }
        }
        if it >= end {
            result += '\\' * (number_backslashes * 2);
            break;
        } elif char == '"' {
            result += '\\' * ((number_backslashes * 2) + 1);
            result += char;
        } else {
            result += '\\' * number_backslashes;
            result += char;
        }
        it += 1;
    }
    result += '"';
    return result;
}