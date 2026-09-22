"""Get field names from a potentially nested record.
    """
def _get_record_fields(d: dict[str, object]) -> object | None {
    if isinstance(d, dict) {
        if "fields" in d {
            return d["fields"];
        }
        for v in d.values() {
            fields = _get_record_fields(v as dict[str, object]);
            if fields {
                return fields;
            }
        }
    }
}