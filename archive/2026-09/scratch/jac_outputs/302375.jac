"""
Flatten a dialogue into a single string
Dialogue are list of turns (list of lists)
"""
def flatten_dialogue(dialogue: list[list[str]]) -> str {
    flattened: list[str] = [];
    for turn in dialogue {
        if turn[0] != "none" {
            flattened.append(" ".join(turn));
        } else {
            flattened.append(turn[1]);
        }
    }
    return " ".join(flattened);
}