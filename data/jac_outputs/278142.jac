"""find all the lemmas associated with the given ibm names
    return a list of name.

    for the golf_dic all lemmas are located at index 0
    """
def find_lemmas(player_name: str, golf_dic_list: list[list[str]]) -> list[str] {
    lemma = [];
    for golf_p_list in golf_dic_list {
        for k in golf_p_list {
            if player_name.strip().lower() == k.strip().lower() {
                lemma = lemma + [golf_p_list[0]];
                break;
            }
        }
    }
    return lemma;
}