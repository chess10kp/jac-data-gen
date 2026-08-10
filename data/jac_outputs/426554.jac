"""
if the words are all in lowercase

>>> all_lowercase(["a", "b", "c"])
True
>>> all_lowercase(["a", "12b", "c12"])
True
>>> all_lowercase(["a", "12b", "C12"])
False
"""
def all_lowercase(title_words: list[str]) -> bool {
    concat_str = ''.join(title_words);
    concat_str.lower() == concat_str
}