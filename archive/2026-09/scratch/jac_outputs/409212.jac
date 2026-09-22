"""
    Converts a given point to a letter grade.

    Parameters:
    A number in range of 0 to 100.

    Returns:
    Letter grade.
    """
def convert_points_to_letter(point: int | float) -> str {
    if point >= 94 {
        grade = 'A';
    } elif point >= 87 and point < 94 {
        grade = 'A-';
    } elif point >= 83 and point < 86 {
        grade = 'B+';
    } elif point >= 80 and point < 83 {
        grade = 'B';
    } elif point >= 77 and point < 80 {
        grade = 'B-';
    } elif point >= 73 and point < 77 {
        grade = 'C';
    } elif point >= 67 and point < 73 {
        grade = 'C-';
    } elif point in range(60, 67) {
        grade = 'D';
    } else {
        grade = 'F';
    }
    return grade;
}