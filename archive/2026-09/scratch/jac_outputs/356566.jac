""" remove dup in sorted array without using another array """
def remove_dup2(a: list[int]) -> list[int] {
    n = len(a);
    j = 0;
    print("before removing -- ", a);
    for i in range(n - 1) {
        if a[i] != a[i + 1] {
            a[j] = a[i];
            j += 1;
        }
    }
    a[j] = a[n - 1];
    print("after removing -- ", a);
    return a[0:j + 1];
}