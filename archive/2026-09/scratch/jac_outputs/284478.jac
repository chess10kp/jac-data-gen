"""
1. Create a reference set of characters out of each item from a list of words.
2. Search list of words for reference anagrams.
3. Return a dictionary with references as keys and a list of their anagrams as values.
"""
def make_anagrams_dict(l: list[str]) -> dict[tuple[str, ...], list[str]] {
    anagrams_dict_raw: dict[tuple[str, ...], list[str]] = {};
    anagrams_dict: dict[tuple[str, ...], list[str]] = {};
    for word in l {
        word_to_list = list(word);
        word_to_list.sort();
        ref = tuple(word_to_list);
        if ref not in anagrams_dict_raw {
            anagrams_dict_raw[ref] = [word];
        } else {
            anagrams_dict_raw[ref].append(word);
        }
    }
    for key in anagrams_dict_raw {
        if len(anagrams_dict_raw[key]) >= 2 {
            anagrams_dict[key] = anagrams_dict_raw[key];
        }
    }
    return anagrams_dict;
}