"""Returns a list of moves from a move string (e.g. '1. e4 e5 2. Nf3 Nc6 *')"""
def getMovesFromString(string: Any) -> object {
    moves = [];
    for i in string.split(" ") {
        if (i in ["*", "1-0", "0-1", "1/2-1/2"]) {
            break;
        }
        if i[0].isnumeric() {
            continue;
        }
        moves.append(i);
    }
    return moves;
}