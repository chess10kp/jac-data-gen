"""determines if there are talent overrides in the original data"""
def talents_override(data: str) -> bool {
    return "${talents.mindbender}" in data or "${talents.void_torrent}" in data;
}