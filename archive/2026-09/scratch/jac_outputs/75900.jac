"""Returns a feature label as a string based on the capitalization and other orthographic characteristics of the string."""
def orth(string: Any) -> object {
    if string.isdigit() {
        return 'DIGIT';
    } elif string.isalnum() {
        if string.islower() {
            return 'LOWER';
        } elif string.istitle() {
            return 'TITLE';
        } elif string.isupper() {
            return 'UPPER';
        } else {
            return 'MIXED';
        }
    } elif string.isspace() {
        return 'SPACE';
    } else {
        return 'OTHER';
    }
}