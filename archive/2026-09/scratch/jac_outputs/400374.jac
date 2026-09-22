"""Map words to integer ids and build the reverse lookup."""
def word_to_word_ids(word_counts: dict[str, int], unk_required: bool) -> tuple[dict[str, int], dict[int, str]] {
    count = 0;
    word_to_id = {};
    id_to_word = {};
    if unk_required {
        word_to_id['<UNK>'] = count;
        id_to_word[count] = '<UNK>';
        count += 1;
    }
    for word in word_counts.keys() {
        word_to_id[word] = count;
        id_to_word[count] = word;
        count += 1;
    }
    (word_to_id, id_to_word)
}