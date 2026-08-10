"""
Creates a double nested dict of question ids containing dict with question text,
and an empty list.
"""
def compile_question_data(surveys: list[list[dict[str, str]]]) -> dict[str, dict[str, list[str]]] {
    if not surveys {
        return {};
    }
    all_questions = {};
    for question in surveys[0] {
        all_questions[question['question id']] = {question['question text']: []};
    }
    all_questions
}