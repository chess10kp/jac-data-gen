"""Formats list of marked characters as a string."""
def format_match_string(marked_chr_list: list[tuple[str, bool]]) -> str {
    chr_list = [];
    mark_prev = False;
    for (chr, mark) in marked_chr_list {
        if mark != mark_prev {
            chr_list.append('(' if mark else ')');
        }
        chr_list.append(chr);
        mark_prev = mark;
    }
    if mark_prev {
        chr_list.append(')');
    }
    return ''.join(chr_list);
}