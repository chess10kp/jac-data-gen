"""Normalizes a normal python list."""
def normalize_arr(arr: list[float]) -> list[float] {
    total = sum(arr);
    if total == 0 {
        print("Arr is empty/All numbers are zero, returning [1], This is a warning");
        return [1];
    }
    return [i / total for i in arr];
}