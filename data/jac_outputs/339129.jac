"""A LingSync document is identified by its `collection` attribute, which is
    valuated by a string like 'sessions', or 'datums'. Sometimes, however,
    there is no `collection` attribute and the `fieldDBtype` attribute is
    used and evaluates to a capitalized, singular analog, e.g., 'Session' or
    'Datum'. This function returns a collection value for a LingSync document.
    """
def get_collection_for_lingsync_doc(doc: dict[str, str | None]) -> str | None {
    type2collection = {
        'Session': 'sessions',
        'Corpus': 'private_corpuses',
        'Datum': 'datums'
    };
    collection = doc.get('collection');
    if not collection {
        fieldDBtype = doc.get('fieldDBtype');
        if fieldDBtype {
            collection = type2collection.get(fieldDBtype);
        }
    }
    return collection;
}