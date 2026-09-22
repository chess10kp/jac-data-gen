"""Return decoded text if it's not already bytes."""
def safe_decode(txt: Any) -> object {
    try {
        return txt.decode();
    } except AttributeError {
        return txt;
    }
}