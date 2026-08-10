"""
    Expected format: `<channel_id>,<from_addr>,<api_url>;<channel_id>,<from_addr>,<api_url>;`

    Returns a tuple.
    The first item is the assumed default junebug channel which can be used as a
    default fallback for JUNEBUG_DEFAULT_CHANNEL_ID.
    The second item is the dictionary that can be passed to JUNEBUG_CHANNELS
    """
def parse_channel_info(data: str) -> tuple[str | None, dict[str, dict[str, str]]] {
    channels: dict[str, dict[str, str]] = {};
    default_channel_id: str | None = None;
    for channel in data.strip().split(';') {
        (channel_id, from_addr, api_url) = channel.split(',');
        if not default_channel_id {
            default_channel_id = channel_id.strip();
        }
        channels[channel_id.strip()] = {
            'FROM_ADDRESS': from_addr.strip(),
            'API_URL': api_url.strip()
        };
    }
    return (default_channel_id, channels);
}