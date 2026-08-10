"""Move spiral down."""
def down(spiral: list[list[int]], coordinates: dict[str, int]) -> bool {
    done = True;
    while coordinates['row'] < len(spiral) {
        row = coordinates['row'];
        col = coordinates['col'];
        if row == len(spiral) - 1 and spiral[row][col] == 0 {
            spiral[row][col] = 1;
            done = False;
            break;
        } elif row + 2 <= len(spiral) - 1 and spiral[row + 2][col] == 0 and spiral[row + 1][col] == 0 {
            spiral[row][col] = 1;
            coordinates['row'] += 1;
            done = False;
        } elif row + 1 == len(spiral) - 1 and spiral[row + 1][col] == 0 {
            spiral[row][col] = 1;
            coordinates['row'] += 1;
            done = False;
        } else {
            break;
        }
    }
    return done;
}