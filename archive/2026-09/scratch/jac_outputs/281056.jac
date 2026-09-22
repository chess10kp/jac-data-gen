"""Round number of filters based on depth multiplier."""
def _round_channels(
    channels: int | float,
    multiplier: float = 1.0,
    divisor: int = 8,
    channel_min: int | None = None
) -> int | float {
    if not multiplier {
        return channels;
    }
    channels *= multiplier;
    channel_min = channel_min or divisor;
    new_channels = max(
        int(channels + divisor / 2) // divisor * divisor,
        channel_min
    );
    if new_channels < 0.9 * channels {
        new_channels += divisor;
    }
    return new_channels;
}