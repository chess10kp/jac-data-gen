"""
Create a basic sequence with the given pieces.

Keyword arguments:

piece_dict -- The pieces dictionary with the quantity of each piece.
"""
def basic_sequence(piece_dict: dict[str, int]) -> list[str] {
    sequence = [];
    for (piece, number) in piece_dict.items() {
        if number < 1 {
            continue;
        }
        times = ("%s " % piece) * number;
        sequence.extend(times.split());
    }
    return sequence;
}