"""Returns relevant BERT dataset name, depending on whether we are using a cased model."""
def get_bert_dataset_name(is_cased: bool) -> str {
    if is_cased {
        return 'book_corpus_wiki_en_cased';
    } else {
        return 'book_corpus_wiki_en_uncased';
    }
}