"""Do list1 and list2 intersect"""
def intersect(list1: list[int], list2: list[int]) -> bool {
    return len(set(list1).intersection(set(list2))) > 0;
}