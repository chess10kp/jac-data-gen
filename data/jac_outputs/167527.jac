""" replace chars that shouldn't be in the answer """
def _sanatize_user_answer(answer: str) -> str | int {
    if answer[0] == "." {
        answer = "0" + answer;
    }
    try {
        return answer.replace("/", ".").replace(",", ".").replace("-", "");
    } except Exception {
        return -2;
    }
}