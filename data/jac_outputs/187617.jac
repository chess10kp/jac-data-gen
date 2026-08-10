"""Check that all items in a list are equal and return True or False
    """
def check_all_equal(lst: list[int]) -> bool {
    not lst or lst.count(lst[0]) == len(lst)
}