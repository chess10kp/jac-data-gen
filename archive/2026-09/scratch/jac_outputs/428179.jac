"""
Returns a truncated string with '..' at the end if it is longer than the length parameter.
If the title param is true a span with the original string as title (for mouse over) is added.
"""
def truncate_string(string: str | None, length: int = 80, title: bool = True) -> str {
    if string is None {
        return '';
    }
    result = string;
    if len(result) > length + 2 {
        if title {
            title_text = result.replace('"', '');
            result = '<span title="' + title_text + '">' + result[:length] + '..' + '</span>';
        } else {
            result = result[:length] + '..';
        }
    }
    return result;
}