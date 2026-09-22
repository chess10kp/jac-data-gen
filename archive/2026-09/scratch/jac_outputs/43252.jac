"""Base64 decode the specified value."""
def base64_decode(decvalue: bytes) -> str {
    msg = """ There was an error. Most likely this isn't a valid Base64 value
    and Python choked on it """;
    try {
        base64dec = decvalue.decode("Base64");
        return base64dec;
    } except Exception {
        return msg;
    }
}