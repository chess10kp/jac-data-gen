"""
    flatten a nested list.
    https://stackoverflow.com/questions/952914/how-to-make-a-flat-list-out-of-list-of-lists
    """
def flatten(l: list[list[object]]) -> list[object] {
    [item for sublist in l for item in sublist]
}