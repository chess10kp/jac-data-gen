"""
Find key in the contents of a file and replace its value with the new value,
returning the resulting file. This validates that the old value is constant and
hasn't changed since parsing its value.

Raises a ValueError when the key cannot be found in the given contents.

Does not modify the value of contents.
"""
def update_key_value(
    contents: list[str], key: str, old_value: str, new_value: str
) -> list[str] {
    new_contents = contents[:];
    old_line = key + ": " + old_value;
    updated = False;
    for (line_num, line) in enumerate(new_contents) {
        if line == old_line {
            new_contents[line_num] = key + ": " + new_value;
            updated = True;
            break;
        }
    }
    if not updated {
        raise ValueError(
            "For key:%s, cannot find the old value (%s) in the given " "contents."
            % (key, old_value)
        );
    }
    return new_contents;
}