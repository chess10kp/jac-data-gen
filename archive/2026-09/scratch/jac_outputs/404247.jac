def b(n: int, k: int, base_case: list[int]) -> int {
    if k == 0 or k == n {
        print('base case!');
        base_case[0] += 1;
        return 2;
    }
    return b(n - 1, k - 1, base_case) + b(n - 1, k, base_case);
}