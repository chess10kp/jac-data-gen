"""Given day of month return English Ordinal Suffix"""
def datesuffix(n: int) -> str {
    if n in (1, 21, 31) {
        suffix = "st";
    } elif n in (2, 22) {
        suffix = "nd";
    } elif n in (3, 23) {
        suffix = "rd";
    } else {
        suffix = "th";
    }
    return suffix;
}