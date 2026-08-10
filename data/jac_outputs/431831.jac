"""Prune url path to the query section starting with 'q='."""
def get_search_params(url_path: str) -> str | list[str] {
    query_params = url_path[len('/search.json?'):];
    query_pos = query_params.find('q=');
    if query_pos == -1 {
        return [];
    }
    query_params = query_params[query_pos + 2:];
    end_pos = query_params.find('&');
    if end_pos != -1 {
        query_params = query_params[:end_pos];
    }
    return query_params;
}