def calculate_grade(percentage: Any) -> object {
    if (percentage >= 90) {
        grade = "A";
    } elif (percentage >= 80) {
        grade = "B";
    } elif (percentage >= 70) {
        grade = "C";
    } else {
        grade = "D";
    }
    return grade;
}



with entry {
    print(calculate_grade(5));
    print(calculate_grade(100));
}
