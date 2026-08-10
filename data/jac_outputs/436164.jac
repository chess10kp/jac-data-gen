"""simple quick sort implementation"""
def quick_sort(values: list[int]) -> list[int] {
    if len(values) == 0 {
        return [];
    } elif len(values) == 1 {
        return values;
    } elif len(values) == 2 {
        if values[0] > values[1] {
            return values[::-1];
        } else {
            return values;
        }
    }
    pivot = values[0];
    less_list = [x for x in values if x < pivot];
    more_list = [x for x in values if x > pivot];
    same_list = [x for x in values if x == pivot];
    less_list = less_list + same_list;
    if len(more_list) == 0 {
        more_list.append(less_list.pop());
    }
    return quick_sort(less_list) + quick_sort(more_list);
}