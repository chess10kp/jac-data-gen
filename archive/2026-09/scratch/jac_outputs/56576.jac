"""Score the dice based on rules for YACHT."""
def yatch(dice: list[int]) -> int {
    points = 0;
    if dice.count(dice[0]) == len(dice) {
        points = 50;
    }
    return points;
}