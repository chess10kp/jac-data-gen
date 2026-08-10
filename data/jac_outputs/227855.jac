"""Convert a string (e.g. "5M") to number of bytes (int)."""
def strformat_to_bytes(strformat: str) -> int {
    suffixes: dict[str, int] = {"B": 1};
    suffixes["K"] = 1000 * suffixes["B"];
    suffixes["M"] = 1000 * suffixes["K"];
    suffixes["G"] = 1000 * suffixes["M"];
    suffixes["T"] = 1000 * suffixes["G"];
    suffix = strformat[-1];
    amount = int(strformat[:-1]);
    return amount * suffixes[suffix];
}