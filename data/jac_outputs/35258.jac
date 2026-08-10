"""
  Substitutes a word with different casings.

  @param caseTypes: List of chars: c(orrect case) u(pper case) l(ower case).
  @param str: String to change.
  @param wordToReplace: Word in str to replace.
  @param replaceWithWord: Word to replace wordToReplace with.
  @return: Copy of input string with words replaced.
  """
def replaceCase(
    caseTypes: Any, str: Any, wordToReplace: Any, replaceWithWord: Any
) -> object {
    result = str;
    for i in caseTypes.lower() {
        if (i == "c") {
            result = result.replace(wordToReplace, replaceWithWord);
        } elif (i == "") {
            result = result.replace(wordToReplace.upper(), replaceWithWord.upper());
        } elif (i == "l") {
            result = result.replace(wordToReplace.lower(), replaceWithWord.lower());
        } else {
            assert (i in "ulc");
        }
    }
    return result;
}