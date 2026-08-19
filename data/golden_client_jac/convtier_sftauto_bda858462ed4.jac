def bubble_sort_recursive(lst: Any) -> object {
    swapped = False;
    for i in range((len(lst) - 1)) {
        if (lst[i] < lst[(i + 1)]) {
            (lst[i], lst[(i + 1)]) = (lst[(i + 1)], lst[i]);
            swapped = True;
        }
    }
    if not swapped {
        return lst;
    } else {
        return bubble_sort_recursive(lst);
    }
}



with entry {
    print(bubble_sort_recursive([2]));
    print(bubble_sort_recursive([34]));
}
