"""
    Shuffles the character of a string by placing each of them
    in a grid (the height is dependent on the key) in a zigzag
    formation and reading it left to right.
    """
def encrypt(input_string: str, key: int) -> str {
    grid = [[] for _ in range(key)];
    lowest = key - 1;
    if key <= 0 {
        raise ValueError("Height of grid can't be 0 or negative");
    }
    if key == 1 or len(input_string) <= key {
        return input_string;
    }
    for (position, character) in enumerate(input_string) {
        num = position % (lowest * 2);
        num = min(num, (lowest * 2) - num);
        grid[num].append(character);
    }
    return "".join(["".join(row) for row in grid]);
}