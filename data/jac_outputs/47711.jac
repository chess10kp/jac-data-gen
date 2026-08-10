"""
Returns True if the manifest.json is a list of the form [{'k' : v}, ...],
where each member dictionary contains an object_id key.
Otherwise, returns False
"""
def is_valid_manifest(manifest_json: list[dict[str, object]], required_keys: list[str]) -> bool {
    for record in manifest_json {
        record_keys = record.keys();
        if not set(required_keys).issubset(record_keys) {
            return False;
        }
    }
    return True;
}