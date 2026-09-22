"""
Decode a message with the rail fence cipher.

:param message string - The encoded text.
:param rails int - The number of rails to use to decode.
:return string - The decoded text.
"""
def decode(encoded_message: str, rails: int) -> str {
    rail_index_max = rails - 1;
    zigzag = [];
    while rails > 0 {
        zigzag.append(["."] * len(encoded_message));
        rails -= 1;
    }
    rail_index = 0;
    col_index = 0;
    alternate = True;
    for (index, char) in enumerate(encoded_message) {
        if rail_index > rail_index_max {
            break;
        }
        zigzag[rail_index][col_index] = char;
        from_horizontal_edge = min(
            rail_index_max - rail_index, abs(0 - rail_index)
        );
        if from_horizontal_edge > 0 and alternate {
            col_index += from_horizontal_edge * 2;
        } else {
            col_index += rail_index_max * 2 - from_horizontal_edge * 2;
        }
        if alternate {
            alternate = False;
        } else {
            alternate = True;
        }
        if col_index >= len(encoded_message) {
            rail_index += 1;
            col_index = rail_index;
            if rail_index > rail_index_max // 2 {
                alternate = True;
            } else {
                alternate = False;
            }
        }
    }
    decoded_message = "";
    direction = '+';
    rail_index = 0;
    for (index, char) in enumerate(encoded_message) {
        decoded_message += zigzag[rail_index][index];
        if rail_index == rail_index_max {
            direction = '-';
        } elif rail_index == 0 {
            direction = '+';
        }
        if direction == '+' {
            rail_index += 1;
        } elif direction == '-' {
            rail_index -= 1;
        }
    }
    return decoded_message;
}