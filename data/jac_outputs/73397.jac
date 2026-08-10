"""Serialize content for bulk deletion API request."""
def serialize_for_deletion(elasticsearch_object_id: str) -> dict[str, str] {
    return {"_id": elasticsearch_object_id, "_op_type": "delete"};
}