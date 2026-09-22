"""Process channel names to obtain electrode names."""
def process_channel_names(channel_names: list[str]) -> list[str] {
    channel_names = [elem.split()[-1] for elem in channel_names];
    channel_names = [elem.replace("-", " ").split()[0] for elem in channel_names];
    return channel_names;
}