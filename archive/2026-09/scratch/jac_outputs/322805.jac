"""Transforms a number to its numeral adverb representation."""
def adverbize(number: int | float | str) -> str {
    number = int(number);
    if number == 1 {
        numeral = "once";
    } elif number == 2 {
        numeral = "twice";
    } elif number == 3 {
        numeral = "thrice";
    } else {
        numeral = f"{number} times";
    }
    return numeral;
}