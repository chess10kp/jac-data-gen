"""Return the first [student name, 100] pair, or [] if none found."""
def perfect_score(student_info: list[list[str | int]]) -> list[str | int] {
    first = [];
    print(student_info);
    for name in student_info {
        print('1', 'name', name[0]);
        print('2', 'score', name[1]);
        print(`type(name[1]));
        score = int(name[1]);
        print(`type(score));
        if score == 100 {
            print('3', score);
            print(name);
            return name;
        }
    }
    return first;
}