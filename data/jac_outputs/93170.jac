"""Remove everything found between instances of start_string and end_string.

Replace each such instance with replace_fn(removed_text)

e.g. _find_and_replace("the [[fat]] cat [[sat]]", "[[", "]]", lambda x: x)
  = "the fat cat sat"
"""
def _find_and_replace(
    text: str, start_string: str, end_string: str, replace_fn: Callable[[str], str]
) -> str {
    ret = "";
    current_pos = 0;
    while True {
        start_pos = text.find(start_string, current_pos);
        if start_pos == -1 {
            ret += text[current_pos:];
            break;
        }
        ret += text[current_pos:start_pos];
        end_pos = text.find(end_string, start_pos + len(start_string));
        if end_pos == -1 {
            break;
        }
        ret += replace_fn(text[start_pos + len(start_string):end_pos]);
        current_pos = end_pos + len(end_string);
    }
    return ret;
}