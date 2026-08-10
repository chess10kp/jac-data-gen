"""

    :param input_list:
    :type input_list:
    :param words_list:
    :type words_list:
    :return:
    :rtype:
    """
def curate_list(input_list: Any, words_list: Any) -> object {
    final_list = [];
    for token in input_list {
        if (len(token.strip()) == 0) {
            continue;
        }
        if (token.strip() in words_list) {
            final_list.append(token.strip());
        }
    }
    return final_list;
}