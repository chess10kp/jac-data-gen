""" assume n is an int >= 0 """
def h(n: int) -> int {
    answer = 0;
    for c in str(n) {
        answer += int(c);
    }
    return answer;
}