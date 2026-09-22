"""Converts a potentially big number into a lisible string.

Example:
- big_number(10000000) returns '10 000 000'.
"""
def big_number(int_in: int) -> str {
    s = str(int_in);
    position = len(s);
    counter = 0;
    out = '';
    while position != 0 {
        counter += 1;
        position -= 1;
        out = s[position] + out;
        if counter % 3 == 0 and position != 0 {
            out = " " + out;
        }
    }
    return out;
}