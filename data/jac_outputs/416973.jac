"""Return True if word not in wordset, nor matched by wildcard.

    Note: accepts a wildcard (default '*') for '0 or more letters'.
    """
def wordinset_wild(word: str, wordset: set[str], wild: str = '*') -> bool {
    if word in wordset {
        return True;
    } else {
        if word[-1] != wild {
            word += wild;
        }
        while len(word) > 2 {
            if word in wordset {
                return True;
            } else {
                word = word[:-2] + wild;
            }
        }
    }
    return False;
}