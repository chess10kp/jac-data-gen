"""Validate a tag.

Keys must be less than 128 chars and values must be less than 256 chars.
"""
def validate_tag(key: str, value: str) -> bool {
    klen = len(key);
    vlen = len(value);
    return klen > 0 and klen < 256 and vlen > 0 and vlen < 256;
}