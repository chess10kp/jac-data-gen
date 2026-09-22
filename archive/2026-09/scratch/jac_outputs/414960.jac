"""Merge word lines split across parenthesis continuations."""
def remove_parenthesis_break(words_list: list[list[str]]) -> list[list[str]] {
    new_words_list = [];
    parenthesis_num = 0;
    new_words = [];
    is_line_end = True;
    for words in words_list {
        if not words {
            continue;
        }
        new_words += words;
        if not words[-1].startswith("//") {
            for word in words {
                if word == "(" {
                    parenthesis_num += 1;
                } elif word == ")" {
                    parenthesis_num -= 1;
                }
            }
            is_line_end = parenthesis_num <= 0;
        } else {
            is_line_end = True;
        }
        if is_line_end {
            new_words_list.append(new_words);
            new_words = [];
        }
    }
    return new_words_list;
}