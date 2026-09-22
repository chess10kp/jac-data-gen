"""Utility function to gin up something that is kind of like a kinto-changes record."""
def changes_record(bucket_id: Any, collection_id: Any) -> object {
    return {
        'id': 'abcd',
        'last_modified': 123,
        'bucket': bucket_id,
        'collection': collection_id,
        'host': 'http://localhost'
    };
}