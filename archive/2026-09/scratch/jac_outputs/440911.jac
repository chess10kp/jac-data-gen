"""Capitalise the first letter of the sentence and add a full stop."""
def sentence_case(sentence: str, exciting: bool = False) -> str {
    sentence = sentence[0].upper() + sentence[1:];
    if sentence[-1] in {'.', '!', '?'} {
        return sentence;
    } elif exciting {
        return sentence + "!";
    } else {
        return sentence + ".";
    }
}