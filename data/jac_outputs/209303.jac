def partition_helper(a: list[int], first: int, last: int) -> int {
    pivot_value = a[first];
    left_mark = first + 1;
    right_mark = last;
    done = False;
    while not done {
        while right_mark >= left_mark and a[left_mark] <= pivot_value {
            left_mark += 1;
        }
        while right_mark >= left_mark and a[right_mark] >= pivot_value {
            right_mark -= 1;
        }
        if right_mark < left_mark {
            done = True;
        } else {
            (a[left_mark], a[right_mark]) = (a[right_mark], a[left_mark]);
        }
    }
    (a[first], a[right_mark]) = (a[right_mark], a[first]);
    return right_mark;
}