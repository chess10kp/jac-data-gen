"""For mapping schemas to schema blocks:
Answer ids will map to the user's response
"""
def get_registration_response_key(question: dict[str, str | int]) -> str | int {
    return question.get('qid', '') or question.get('id', '');
}