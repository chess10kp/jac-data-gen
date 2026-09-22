"""Handle Python 2/3 differences in argv encoding"""
def get_lower(somedata: bytes | str) -> str {
    result = "";
    try {
        result = (somedata as bytes).decode("utf-8").lower();
    } except Exception {
        result = (somedata as str).lower();
    }
    return result;
}