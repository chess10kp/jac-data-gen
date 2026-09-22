"""
    Convert the compilation arguments (include folder and #defines)
    to checked C format.
"""
def getCheckedCArgs(argument_list: list[str]) -> list[str] {
    return [
        '-extra-arg=' + curr_arg
        for curr_arg in argument_list
        if curr_arg.startswith(('-D', '-I'))
    ];
}