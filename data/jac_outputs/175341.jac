"""returns a list of the elements that are
    not in common"""
def drop_matches(list1: list[int], list2: list[int]) -> tuple[int, list[int]] {
    list1.sort();
    list2.sort();
    matches = [];
    i = 0;
    j = 0;
    len_lst1 = len(list1);
    len_lst2 = len(list2);
    while i < len_lst1 and j < len_lst2 {
        if list1[i] < list2[j] {
            matches.append(list1[i]);
            i += 1;
        } elif list1[i] > list2[j] {
            matches.append(list2[j]);
            j += 1;
        } else {
            i += 1;
            j += 1;
        }
    }
    while i < len_lst1 {
        matches.append(list1[i]);
        i += 1;
    }
    while j < len_lst2 {
        matches.append(list2[j]);
        j += 1;
    }
    return (len(matches), matches);
}