"""Judge whether is valid para."""
def judge_para(data: dict[str, dict[str, list[str]]]) -> bool {
    for (_, para_tokens) in data["context"].items() {
        if len(para_tokens) == 1 {
            return False;
        }
    }
    return True;
}