"""
    Return the URN of a raw group update

    Example: urn:li:fs_miniProfile:<id>
    Example: urn:li:fs_updateV2:(<urn>,GROUP_FEED,EMPTY,DEFAULT,false)
    """
def get_urn_from_raw_update(raw_string: str) -> str {
    raw_string.split("(")[1].split(",")[0]
}