"""
Takes a list of tuples with index 0 being the text_id and index 1 being a
list of sentences and broadcasts the text_id to each sentence.
"""
def tup_list_maker(tup_list: list[tuple[int | str, list[str]]]) -> list[tuple[int | str, str]] {
    final_list = [];
    for (index, sentences) in tup_list {
        for sentence in sentences {
            final_list.append((index, sentence));
        }
    }
    return final_list;
}