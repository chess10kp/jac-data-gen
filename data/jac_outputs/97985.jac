"""The function that check the number and return the unit."""
def check_unit(number: float) -> str {
    if number > 1 {
        return "square meters";
    }
    return "square meter";
}