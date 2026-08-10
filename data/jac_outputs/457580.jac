"""Make a dictionary of how many of each value are in the dice."""
def dice_counts(dice: list[int]) -> dict[int, int] {
    return {x: dice.count(x) for x in range(1, 7)};
}