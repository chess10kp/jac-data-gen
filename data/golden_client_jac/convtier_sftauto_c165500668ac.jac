def group_students(student_list: Any) -> object {
    result = {};
    for student in student_list {
        major = student['major'];
        name = student['name'];
        result.setdefault(major, []).append(name);
    }
    return result;
}



with entry {
    print(group_students([]));
}
