"""
    checks if given id is valid TC ID
    """
def is_turkish_id(x: Any) -> object {
    if (len(str(x)) != 11) {
        return False;
    }
    str_id = str(x);
    lst_id = [
        int(n)
        for n in str_id
        if n.isdigit()
    ];
    if (lst_id[0] == 0) {
        return False;
    }
    first_10_sum = sum(lst_id[:10]);
    if ((first_10_sum % 10) != lst_id[-1]) {
        return False;
    }
    total_odds = sum(lst_id[0::2][:-1]);
    total_evens = sum(lst_id[1::2][:-1]);
    is_10 = (((total_odds * 7) + (total_evens * 9)) % 10) == lst_id[9];
    is_11 = ((total_odds * 8) % 10) == lst_id[-1];
    if (not is_10 or not is_11) {
        return False;
    } else {
        return True;
    }
}