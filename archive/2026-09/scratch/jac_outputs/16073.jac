"""return params as SmashGG friendly query string"""
def _prepare_params(params: list[str]) -> str {
    query_string = '';
    if len(params) == 0 {
        return query_string;
    }
    prefix = '?expand[]=';
    query_string = prefix + '&expand[]='.join(params);
    return query_string;
}