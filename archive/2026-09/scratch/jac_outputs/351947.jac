"""Rename BH1 -> BHN, BH2 -> BHE for consistency."""
def rename_channel(channel: str) -> str {
    match channel {
        case "BH1":
            return "BHN";
        case "BH2":
            return "BHE";
        case _:
            return channel;
    }
}