"""Checks for metadata in variables. These are separated from the "key"
metadata by underscore. Not used anywhere at the moment for anything
other than descriptiveness"""
def has_metadata(info: str) -> str {
    parts = info.split('_', 1);
    if len(parts) == 1 {
        return info;
    }
    (key, metadata) = (parts[0], parts[1]);
    return key if metadata else info;
}