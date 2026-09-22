"""
Takes string with partial sentence and returns
list of words with spaces included.

Leading space is attached to first word.
Later spaces attached to prior word.
"""
def split_with_spaces(sentence: str) -> list[str] {
    sentence_list: list[str] = [];
    curr_word = "";
    for c in sentence {
        if c == " " and curr_word != "" {
            sentence_list.append(curr_word + " ");
            curr_word = "";
        } else {
            curr_word += c;
        }
    }
    if len(curr_word) > 0 {
        sentence_list.append(curr_word);
    }
    return sentence_list;
}