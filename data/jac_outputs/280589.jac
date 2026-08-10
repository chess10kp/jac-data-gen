"""Parse comma-separated numeric strings into integers."""
def num2int(num: str) -> int {
    return int(num.replace(',', ''));
}