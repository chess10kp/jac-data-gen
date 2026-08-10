"""Get the index of a token in the text."""
def get_token_index(char_positions: list[int], text: str) -> list[int] {
    space = [' ', '\n', '\t'];
    res: list[int] = [];
    index = 0;
    start = False;
    for i in range(len(text) - 1) {
        if text[i] not in space {
            start = True;
        }
        if text[i] in space and text[i + 1] not in space and start {
            index += 1;
        }
        if i in char_positions {
            res.append(index);
        }
    }
    if len(text) - 1 in char_positions {
        res.append(index);
    }
    return res;
}