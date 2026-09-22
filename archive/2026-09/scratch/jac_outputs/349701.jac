"""Filter empty inputs or targets."""
def filter_empty(input_list: list[str], target_list: list[str]) -> tuple[list[str], list[str]] {
    return_input = [];
    return_target = [];
    for (inp, tar) in zip(input_list, target_list) {
        if inp and tar {
            return_input.append(inp);
            return_target.append(tar);
        }
    }
    return (return_input, return_target);
}