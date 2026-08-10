"""Calibrate the begin char position of each token in the sentence."""
def token_begin_char_calibrate(token_value: dict[str, str], text: str) -> dict[str, int] | None {
    res = {};
    ptr = 0;
    for key in sorted(token_value.keys()) {
        token = token_value[key];
        ptr_t = 0;
        while ptr_t < len(token) {
            if ptr >= len(text) {
                print('Calibration failed!');
                return None;
            }
            if text[ptr] == token[ptr_t] {
                if ptr_t == 0 {
                    res[key] = ptr;
                }
                ptr += 1;
                ptr_t += 1;
            } else {
                ptr += 1;
            }
        }
    }
    assert len(token_value) == len(res);
    return res;
}