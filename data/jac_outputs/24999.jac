"""Form line."""
def form_line(ltokens: list[object] | tuple[object, ...] | int | float | str | bool | None = [], rtokens: list[object] | tuple[object, ...] = []) -> str {
    if not isinstance(ltokens, (list, tuple)) {
        return str(ltokens) + ';';
    }
    ltext = ' '.join(map(str, ltokens));
    rtext = ' '.join(map(str, rtokens));
    if len(rtokens) > 0 {
        return '{ltext} = {rtext};'.format(ltext=ltext, rtext=rtext);
    }
    return '{ltext};'.format(ltext=ltext);
}