def count_string(s_string: str) -> int {
    s_value = eval(s_string) as str;
    return len(s_string) - len(s_value);
}