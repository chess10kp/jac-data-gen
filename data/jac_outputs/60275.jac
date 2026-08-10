""" Validate user answer """
def solve(result: int, answer: str) -> bool {
    try {
        return result == int(answer);
    } except ValueError {
        return False;
    }
}