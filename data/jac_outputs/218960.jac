"""Gets pairs of three whose sum is 0."""
def three_sum(a: list[int], s: int) -> int {
    a.sort();
    answer_set = [];
    for i in range(len(a) - 3) {
        l = i + 1;
        r = len(a) - 1;
        while r > l {
            if a[i] + a[r] + a[l] == s and a[r] > a[l] > a[i] {
                answer_set.append((a[i], a[r], a[l]));
                l += 1;
            } elif a[i] + a[r] + a[l] < s {
                l += 1;
            } else {
                r -= 1;
            }
        }
    }
    if answer_set {
        return 1;
    }
    return 0;
}