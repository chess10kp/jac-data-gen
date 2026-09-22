"""Join parenthesized fraction tokens in a text list into single strings."""
def joint_number(text_list: list[str]) -> list[str] {
    new_list = [];
    i = 0;
    while i < len(text_list) {
        if text_list[i] == '(' and i + 4 < len(text_list) and text_list[i + 4] == ')' {
            new_list.append(''.join(text_list[i:i + 5]));
            i = i + 5;
        } else {
            new_list.append(text_list[i]);
            i += 1;
        }
    }
    return new_list;
}