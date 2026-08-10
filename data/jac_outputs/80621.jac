"""
    Description:

        Function to make a smaller list which doesn't contain the 'seen' key

    Arguments:

        articles_list {list} : list contains dictionary's with the 'seen' and 'articles' keys

    Returns:

        news_list {list} : list containing just the 'articles' jey from the list in arguments
    """
def news_dictionary_maker(articles_list: list) -> list {
    news_list = [];
    x = 0;
    for i in articles_list {
        if (articles_list[x]['seen'] == 0) {
            news_list.append(articles_list[x]['articles']);
        }
        x = x + 1;
    }
    return news_list;
}