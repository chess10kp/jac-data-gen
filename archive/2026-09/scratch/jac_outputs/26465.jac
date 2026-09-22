"""Returns the largest palindrome made from the product of two 3-digit
    numbers which is less than n."""
def solution(n: int) -> int {
    answer = 0;
    for i in range(999, 99, -1) {
        for j in range(999, 99, -1) {
            t = str(i * j);
            if t == t[::-1] and i * j < n {
                answer = max(answer, i * j);
            }
        }
    }
    return answer;
}