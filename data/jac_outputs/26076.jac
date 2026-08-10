"""Remove leading spaces that are present in all lines of ``text``.

    Parameters
    ----------
    test : str
        The text from which leading spaces should be removed.
    skip1 : bool
        Ignore the first line when determining number of spaces to unindent,
        and remove all leading whitespaces from it.
    """
def unindent(text: Any, skip1: Any = False) -> object {
    lines = text.splitlines();
    ws_lead = [];
    for line in lines[skip1:] {
        len_stripped = len(line.lstrip(' '));
        if len_stripped {
            ws_lead.append((len(line) - len_stripped));
        }
    }
    if (len(ws_lead) > skip1) {
        rm = min(ws_lead);
        if rm {
            if skip1 {
                lines[0] = (' ' * rm) + lines[0].lstrip();
            }
            text = '\n'.join(line[rm:] for line in lines);
        }
    }
    return text;
}