"""Get minimal value of list and its count."""
def min_count1(lst: list[int]) -> list[int] {
    if len(lst) == 0 {
        return [];
    }
    count = 0;
    min_value = lst[0];
    for num in lst {
        if num == min_value {
            count += 1;
        } elif num < min_value {
            count = 1;
            min_value = num;
        }
    }
    return [min_value, count];
}