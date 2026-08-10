"""Get lats and longs to mark on map."""
def getcardinals(minv: int, maxv: int, stepv: int) -> list[int] {
    cardinals = [val for val in range(minv, maxv) if val % stepv == 0];
    if len(cardinals) > 10 {
        return [cardinal[1] for cardinal in enumerate(cardinals) if cardinal[0] % 2 > 0];
    }
    return cardinals;
}