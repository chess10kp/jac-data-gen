"""Concatenate responses with alternating __p1__ / __p2__ speaker tags."""
def add_person_tokens(
    responses: list[str], first_speaker: int | None = None, last_speaker: int = 1
) -> str {
    if first_speaker is None {
        first_speaker = ((last_speaker + len(responses)) % 2) + 1;
    }
    speaker = first_speaker;
    text = '';
    for response in responses {
        tag = f"__p{speaker}__";
        text += ' ' + tag + ' ' + response;
        speaker = 1 if speaker == 2 else 2;
    }
    return text.strip();
}