"""Removes all balanced delimiters. Handles multiple levels and ignores those contained within text delimiters."""
def parse_balanced_delimiters(
    _input: str, _d_left: str, _d_right: str, _text_qualifier: str
) -> tuple[list[str], str] {
    _depth = 0;
    _balanced = [];
    _cleared = "";
    _text_mode = False;
    _start_pos: int | None = None;
    _clear_start_pos: int | None = 0;
    for _curr_idx in range(len(_input)) {
        _curr_char = _input[_curr_idx];
        if _curr_char == _text_qualifier {
            _text_mode = not _text_mode;
        } elif not _text_mode {
            if _curr_char == _d_left {
                if _depth == 0 {
                    _start_pos = _curr_idx;
                    _cleared += _input[_clear_start_pos:_curr_idx];
                    _clear_start_pos = None;
                }
                _depth += 1;
            } elif _curr_char == _d_right {
                _depth -= 1;
            }
            if _start_pos and _depth == 0 and _start_pos < _curr_idx {
                _balanced.append(_input[(_start_pos + 1):_curr_idx]);
                _start_pos = None;
                _clear_start_pos = _curr_idx + 1;
            }
        }
    }
    if _cleared == "" {
        return (_balanced, _input);
    }
    return (_balanced, _cleared);
}