"""Merge sort, duh?

    :param list: List of things to sort
    :return: Cool sorted list
    """
def merge_sort(`list: Any) -> object {
    if (len(`list) > 1) {
        middle = len(`list) // 2;
        left = merge_sort(`list[:middle]);
        right = merge_sort(`list[middle:]);
        `list = [];
        while ((len(left) > 0) and (len(right) > 0)) {
            if (left[0] < right[0]) {
                `list.append(left[0]);
                left.pop(0);
            } else {
                `list.append(right[0]);
                right.pop(0);
            }
        }
        for item in left {
            `list.append(item);
        }
        for item in right {
            `list.append(item);
        }
    }
    return `list;
}