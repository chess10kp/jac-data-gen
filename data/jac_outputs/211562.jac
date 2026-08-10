"""Special-case hackery, perhaps eventually more parameterized ..."""
def normalizeAnswer(answer: Any, yes: Any = None, missing: Any = None) -> object {
    if (answer in (None, "")) {
        answer = missing;
    } elif (answer.lower() == yes) {
        answer = "yes";
    } else {
        answer = "no";
    }
    return answer;
}