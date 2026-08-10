"""Removes all content inside brackets"""
def remove_text_inside_brackets(text: str, brackets: str = "()[]{}") -> str {
    count = [0] * (len(brackets) // 2);
    saved_chars = [];
    for character in text {
        for (idx, brack) in enumerate(brackets) {
            if character == brack {
                kind = idx // 2;
                is_close = idx % 2;
                count[kind] += -1 ** is_close;
                if count[kind] < 0 {
                    count[kind] = 0;
                } else {
                    break;
                }
            }
        } else {
            if not any(count) {
                saved_chars.append(character);
            }
        }
    }
    return ''.join(saved_chars);
}