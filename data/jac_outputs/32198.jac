"""Callback to set initial value of blue slider from dict."""
def bCallback(dataset: str, geneid: str, colors: dict[str, str]) -> int {
    _ = geneid;
    try {
        return int(colors[dataset][4:-1].split(',')[2]);
    } except KeyError {
        return 0;
    }
}