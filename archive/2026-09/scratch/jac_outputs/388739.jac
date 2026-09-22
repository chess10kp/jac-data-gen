"""
    Helper function to convert a string representation back to a number.
    Assumptions:
     * It may have a thousand separator
     * It may have a decimal point
     * If it has a thousand separator then it will have a decimal point
    It will return false is the number doesn't look valid
"""
def convert_repr_number(number: str) -> float | bool {
    sep = "";
    dec = "";
    part_one = "0";
    part_two = "";
    for digit in number {
        if digit.isdigit() {
            if sep == "" {
                part_one += digit;
            } else {
                part_two += digit;
            }
        } elif digit == "-" and part_one == "0" {
            part_one = "-0";
        } elif sep == "" and sep != digit {
            sep = digit;
        } elif dec == "" {
            dec = digit;
            part_two += ".";
        } else {
            return False;
        }
    }
    if dec == "" {
        return float(f"{part_one}.{part_two}");
    }
    return float(f"{part_one}{part_two}");
}