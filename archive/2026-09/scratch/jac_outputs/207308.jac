def studentGrades(gradeList: list[list[str | int]] | int) -> list[int] | str {
    if type(gradeList) == list {
        grades = gradeList as list[list[str | int]];
        ave_grade: list[int] = [];
        for x in range(1, len(grades)) {
            total_grade = 0;
            for y in range(1, len(grades[x])) {
                total_grade += grades[x][y] as int;
            }
            ave = int(total_grade / (len(grades[x]) - 1));
            ave_grade.append(ave);
        }
        return ave_grade;
    }
    return "error";
}