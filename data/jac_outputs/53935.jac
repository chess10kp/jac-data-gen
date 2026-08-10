"""
    Parse course viewed statements.

    Extract the students that have viewed the course from the course viewed statements.
    Return a list of those students.

    :param json: All the course viewed statements since a certain time.
    :type json: dict(str, str)
    :return: List of students who have viewed the course.
    :rtype: list(str)
    """
def parse_viewed_courses(json: Any) -> object {
    student_list = [];
    for statement in json['statements'] {
        student_id = statement['actor']['account']['name'];
        if (student_id not in student_list) {
            student_list.append(student_id);
        }
    }
    return student_list;
}