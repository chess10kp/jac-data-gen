"""Delete all words in the sentence coming either <delete_part>='before'
    or <delete_part>='after'"""
def delete_part(
    sentence: Any, delete_part: Any, mainword: Any, **kwargs: Any
) -> object {
    if (mainword not in sentence) {
        return (False, sentence);
    }
    senthalved = sentence.split(mainword);
    if (delete_part == 'after') {
        return (True, senthalved[0]);
    }
    if (delete_part == 'before') {
        return (True, senthalved[-1]);
    }
}