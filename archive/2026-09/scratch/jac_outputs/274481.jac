"""Count questions any group member answered with yes."""
def count_any_question_yes(group_input: str) -> int {
    return len(set("".join([line.strip() for line in group_input.split("\n")])));
}