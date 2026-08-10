"""Save a Vocab file for test."""
def save_a_vocab_file(vocab_file: str, vocab_list: list[str]) -> str {
    with open(vocab_file, "w", encoding='utf-8') as out_f {
        for vocab in vocab_list {
            out_f.write(vocab);
            out_f.write('\n');
        }
    }
    return vocab_file;
}