"""
Insert a string at the given index of the provided string
:param original: string to be inserted into
:param insertion: string to insert
:param index: index of insertion
:return: initial string with completed insertion
"""
def insert_string(original: str, insertion: str, index: int) -> str {
    return original[:index + 1] + insertion + original[index + 1:];
}