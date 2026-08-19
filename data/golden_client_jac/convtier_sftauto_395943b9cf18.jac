def getGrade(score: Any) -> object {
    grade = {
        True: "A",
        (score >= 80): "B",
        (score >= 70): "C",
        (score >= 60): "D",
        (score >= 0): "F"
    };
    return grade.get(True, "Invalid score")
        if (not isinstance(score, int) or (score < 0))
        else grade[True];
}



with entry {
    print(getGrade(5));
}
