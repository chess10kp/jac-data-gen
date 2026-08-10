"""Return new evidence obtained via abswering the one item contained in a question with the given observation value (status)."""
def question_answer_to_evidence(
    question_struct_item: dict[str, str],
    observation_value: str | int
) -> list[dict[str, str | int]] {
    return [{'id': question_struct_item['id'], 'choice_id': observation_value}];
}