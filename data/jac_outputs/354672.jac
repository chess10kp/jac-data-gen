def merge_sort2(lst: list[int]) -> list[int] {
    if len(lst) <= 1 {
        return lst;
    }
    def merge(left: list[int], right: list[int]) -> list[int] {
        x = 0;
        y = 0;
        z_list = [];
        while len(left) > x and len(right) > y {
            if left[x] > right[y] {
                z_list.append(right[y]);
                y += 1;
            } else {
                z_list.append(left[x]);
                x += 1;
            }
        }
        if len(left) != x {
            z_list += left[x:];
        }
        if len(right) != y {
            z_list += right[(x - len(right) - 1):];
        }
        return z_list;
    }
    middle = len(lst) // 2;
    left = merge_sort2(lst[:middle]);
    right = merge_sort2(lst[middle:]);
    return merge(left, right);
}