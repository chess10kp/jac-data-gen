""" return list of words of a specified length in the list """
def getWordsUnder(wordList: list[str], targetLength: int) -> list[str] {
    return [
        word
        for word in wordList
        if len(word) < targetLength
    ];
}