"""Function for word preprocessing."""
def word_preprocessing(
    word: str,
    ignore_non_alnumspc: bool = True,
    ignore_space: bool = True,
    ignore_numeric: bool = True,
    ignore_case: bool = True
) -> str {
    if ignore_non_alnumspc {
        word = "".join(filter(lambda (x: str) { x.isalnum() or x.isspace(); }, word));
    }
    if ignore_space {
        word = "".join(filter(lambda (x: str) { not x.isspace(); }, word));
    }
    if ignore_numeric {
        word = "".join(filter(lambda (x: str) { not x.isnumeric(); }, word));
    }
    if ignore_case {
        word = word.lower();
    }
    return word;
}