"""
    Modified counting sort, where k = base
    """
def counting_sort(arr: list[int], exp: int, base: int = 10) -> list[int] {
    length = len(arr);
    output = [0] * length;
    count_arr = [0] * base;
    for el in arr {
        index = el // exp;
        count_arr[index % base] += 1;
    }
    for i in range(1, 10) {
        count_arr[i] += count_arr[i - 1];
    }
    for el in arr[::-1] {
        index = el // exp;
        output[count_arr[index % base] - 1] = el;
        count_arr[index % base] -= 1;
    }
    output
}