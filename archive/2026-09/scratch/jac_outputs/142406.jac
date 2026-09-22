"""ES query by Twitter's author_id

    Args:
        author_id (str)

    Returns:
        ES query (JSON)

    Note:
        INCA

    """
def query_tw_author_id(author_id: Any) -> object {
    return {
        "query": {
            "bool": {
                "filter": [
                    {"term": {"doctype": "tweets2"}},
                    {"match": {"author_id": author_id}}
                ]
            }
        }
    };
}