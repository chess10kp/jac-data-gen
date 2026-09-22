"""
Function that takes a list, each of whose entries is a list
containing two entries, and assembles two separate lists, one
for each of these entries
"""
def splitOneListIntoTwo(inputList: list[list[int | str]]) -> tuple[list[int | str], list[int | str]] {
    list1 = [entry[0] for entry in inputList];
    list2 = [entry[1] for entry in inputList];
    return (list1, list2);
}