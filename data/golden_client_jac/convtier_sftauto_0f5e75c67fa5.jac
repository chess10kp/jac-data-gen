def clear_line_breaks(string: Any) -> object {
    string = string.replace("\n", "").replace("\r\n", "");
    lines = [line.strip() for line in string.splitlines()];
    result = "\n".join(lines);
    return result;
}



with entry {
    print(clear_line_breaks('hello'));
    print(clear_line_breaks('Racecar'));
    print(clear_line_breaks('abcabc'));
}
