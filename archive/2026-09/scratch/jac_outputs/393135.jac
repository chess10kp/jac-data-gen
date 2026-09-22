"""sort"""
def sort(arr: list[int | float]) -> list[int | float] {
    l = len(arr);
    for i in range(0, l) {
        for j in range(i + 1, l) {
            if arr[i] >= arr[j] {
                tmp = arr[i];
                arr[i] = arr[j];
                arr[j] = tmp;
            }
        }
    }
    return arr;
}