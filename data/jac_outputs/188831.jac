""" Exract word (space separated ) at current index"""
def extractWordInString(str_to_parse: str, index: int) -> str {
    i = index;
    while i != 0 and str_to_parse[i - 1] not in " \t\n&|" {
        i = i - 1;
    }
    left_part = str_to_parse[i:index];
    i = index;
    while i != len(str_to_parse) and str_to_parse[i] not in " \t\n&|" {
        i = i + 1;
    }
    right_part = str_to_parse[index:i];
    return left_part + right_part;
}