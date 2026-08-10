"""
    function that checks for the similarity between the words of
    two strings.

    :param x: first string
    :param y: second string

    :return: returns a float number which is the result of the
     division of the length of the intersection between the two strings'
     words by the length of their union.
     """
def similar(x: Any, y: Any) -> object {
    result = '';
    x_list = x.split();
    x_list = [word.lower() for word in x_list];
    x_list = `list(`set(x_list));
    y_list = y.split();
    y_list = [word.lower() for word in y_list];
    y_list = `list(`set(y_list));
    intersection = [
        word
        for word in x_list
        if (word in y_list)
    ];
    union = `list(`set(x_list).union(y_list));
    result = float((len(intersection) / len(union)));
    return result;
}