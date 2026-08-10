"""remove duplicates"""
def removeDuplicatesList(value: list[int]) -> list[int] {
    print(value);
    return list(dict.fromkeys(value));
}