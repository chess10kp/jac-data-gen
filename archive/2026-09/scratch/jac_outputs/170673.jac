"""Parses the word and counts the number of digits, lowercase letters,
    uppercase letters, and symbols. Returns a dictionary with the results.
    If any character in the word is not in the set of digits, lowercase
    letters, uppercase letters, or symbols it is marked as a bad character.
    Words with bad characters are not output."""
def parse_word(word: Any, s: Any) -> object {
    count = {'d': 0, 'l': 0, '': 0, 's': 0, 'x': 0};
    d = '0123456789';
    l = 'abcdefghijklmnopqrstuvwxyz';
    u = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for c in word {
        if (c in d) {
            count['d'] += 1;
        } elif (c in l) {
            count['l'] += 1;
        } elif (c in u) {
            count[''] += 1;
        } elif (c in s) {
            count['s'] += 1;
        } else {
            count['x'] += 1;
        }
    }
    return count;
}