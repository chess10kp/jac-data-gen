"""
    Preprocesses a specific format of filters
    Each clause (split by AND) of a filter becomes a separate filter
    Also include the combined set of filters (combined with AND)

    :param documents: The list of documents with filters

    :return: The updated list of documents
    """
def preprocess_filters(documents: list) -> list {
    for document in documents {
        if ('filters' not in document) {
            continue;
        }
        filters = [];
        for value in document['filters'] {
            clauses = value.split(' AND ');
            filters += clauses;
            if (len(clauses) > 1) {
                filters.append(value);
            }
        }
        if (len(document['filters']) > 1) {
            filters.append(' AND '.join(document['filters']));
        }
        document['filters'] = filters;
    }
    return documents;
}