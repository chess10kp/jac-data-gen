"""Return an inversion count and sorted list."""
def sort_and_count_inversions(a_list: list[int]) -> tuple[int, list[int]] {
    inversion_count = 0;
    sorted_list: list[int] = [];
    n = len(a_list);
    if n <= 1 {
        return (0, a_list);
    }
    (first_count, first_list) = sort_and_count_inversions(a_list[0:int(n / 2)]);
    (second_count, second_list) = sort_and_count_inversions(a_list[int(n / 2):]);
    first_length = len(first_list);
    second_length = len(second_list);
    i = 0;
    j = 0;
    for z in range(n) {
        if i == first_length {
            sorted_list.append(second_list[j]);
            j += 1;
        } elif j == second_length {
            sorted_list.append(first_list[i]);
            i += 1;
        } elif first_list[i] < second_list[j] {
            sorted_list.append(first_list[i]);
            i += 1;
        } else {
            sorted_list.append(second_list[j]);
            j += 1;
            inversion_count += first_length - i;
        }
    }
    inversion_count += first_count + second_count;
    return (inversion_count, sorted_list);
}