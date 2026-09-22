"""
    The navigation subsystem syntax is made of several lines containing chunks.
    There are one or more chunks on each line, and chunks contain zero or more other chunks.

    Every chunk must open and close with one of four legal pairs of matching characters:
    If a chunk opens with (, it must close with ).
    If a chunk opens with [, it must close with ].
    If a chunk opens with {, it must close with }.
    If a chunk opens with <, it must close with >.

    Some lines are incomplete, but others are corrupted. Find and discard the corrupted lines first.
    A corrupted line is one where a chunk closes with the wrong character

    To calculate the syntax error score for a line, take the first illegal character on the line:
    ): 3 points.
    ]: 57 points.
    }: 1197 points.
    >: 25137 points.

    What is the total syntax error score for those errors?
    """
def part1(data: list[str]) -> int {
    syntax_error_score = 0;
    points = {")": 3, "]": 57, "}": 1197, ">": 25137};
    char_check = {"(": ")", "[": "]", "{": "}", "<": ">"};
    for line in data {
        found_illegal_char = False;
        active_chunks = [];
        for char in line {
            if not found_illegal_char {
                if char in ("(", "[", "{", "<") {
                    active_chunks.append(char);
                } elif char == char_check[active_chunks[-1]] {
                    active_chunks.pop(-1);
                } else {
                    print(f"Expected close to {active_chunks[-1]} but found {char}");
                    found_illegal_char = True;
                    syntax_error_score += points[char];
                }
            }
        }
    }
    return syntax_error_score;
}