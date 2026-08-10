"""
    Return number of dic1 keys found in dic2.

    >>> d1 = {'hallo': 1, 'hello' : 1}
    >>> d2 = {'hallo': 1, 'hello' : 1, "bonjour" : 1}
    >>> get_nr_dic1_keys_in_dic2(d1, d2)
    2
    >>> d1 = {'hollo': 1, 'ciao' : 1}
    >>> get_nr_dic1_keys_in_dic2(d1, d2)
    0

    """
def get_nr_dic1_keys_in_dic2(dic1: Any, dic2: Any) -> object {
    assert dic1 , "dic1 empty";
    assert dic2 , "dic2 empty";
    dic1_keys_found = 0;
    for key in dic1 {
        if (key in dic2) {
            dic1_keys_found += 1;
        }
    }
    return dic1_keys_found;
}