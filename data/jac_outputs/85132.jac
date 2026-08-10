def set_of_feeds_from_list_of_dics(connections_list_of_dics: list[dict[str, str | int]]) -> set[int] {
    list_of_feeds = [];
    for connection_dic in connections_list_of_dics {
        if connection_dic['from type'] == 'feed' {
            list_of_feeds.append(connection_dic['from temp index']);
        }
    }
    return set(list_of_feeds);
}