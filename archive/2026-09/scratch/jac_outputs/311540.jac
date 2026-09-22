"""Return a list of ids given either objects with ids or a list of ids."""
def extract_ids(objects_or_ids: list) -> list {
    try {
        ids = [`obj.id for `obj in objects_or_ids];
    } except Exception {
        ids = objects_or_ids;
    }
    return ids;
}