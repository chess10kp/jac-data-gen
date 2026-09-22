"""Split column name in data frame columns whenever there is a dot between 2 words.
    E.g. price.availableSupply -> priceAvailableSupply."""
def split_cols_with_dot(column: str) -> str {
    def replace(string: str, char: str, index: int) -> str {
        return string[:index] + char + string[index + 1:];
    }
    if "." in column {
        (part1, part2) = column.split(".");
        return part1 + replace(part2, part2[0].upper(), 0);
    }
    return column;
}