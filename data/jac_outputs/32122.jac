"""
    Check if any number present in Given String
    params:  word - string
    returns:  0 or 1
    """
def is_num_present(word: Any) -> object {
    check = `any(letter.isdigit() for letter in word);
    return 1 if check else 0;
}