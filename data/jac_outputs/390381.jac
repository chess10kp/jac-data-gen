"""Get relative strength index momentum."""
def get_rsi_mom(
    oversold: str, overbought: str, weak: str, strong: str, lt_rsi_mom: str
) -> str {
    match lt_rsi_mom.lower() {
        case "overbought":
            return overbought;
        case "oversold":
            return oversold;
        case "weak":
            return weak;
        case "strong":
            return strong;
        case _:
            return '';
    }
}