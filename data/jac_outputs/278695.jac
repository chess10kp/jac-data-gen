"""Extract parameters from the input and update the current location."""
def get_parameters(current: int, puzzle_input: list[int], opcode: str) -> tuple[list[int], int] {
    if opcode == '03' or opcode == '04' {
        params = [puzzle_input[current]];
        current += 1;
    } else {
        params = [
            puzzle_input[current],
            puzzle_input[current + 1],
            puzzle_input[current + 2]
        ];
        current += 3;
    }
    return (params, current);
}