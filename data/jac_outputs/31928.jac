"""assumes string1 and string2 are string of alphabetical chars of any case
    returns a boolean, True is string1 and string2 are casse insensite anagrams
    else False
    """
def isAnagram(string1: str, string2: str) -> bool {
    sorted(string1.lower()) == sorted(string2.lower())
}