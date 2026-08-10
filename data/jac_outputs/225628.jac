"""http://stackoverflow.com/questions/952914/making-a-flat-list-out-of-list-of-lists-in-python"""
def flatten_list_of_lists(l: list[list[str | int]]) -> list[str | int] {
    return [item for sublist in l for item in sublist];
}