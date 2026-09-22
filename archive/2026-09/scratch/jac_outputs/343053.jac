"""Inserts dash between two odd numbers."""
def insert_dash_between_odds_common(number: int) -> str {
    digits = str(number);
    result = "";
    for (index, digit) in enumerate(digits) {
        result += digit;
        if index + 1 < len(digits) and int(digits[index]) % 2 and int(digits[index + 1]) % 2 {
            result += "-";
        }
    }
    return result;
}