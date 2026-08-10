"""Base64 encode the specified value. Example Format: SGVsbG8gV29ybGQ="""
def base64_encode(encvalue: str) -> bytes | str {
    basedata: bytes | str;
    try {
        basedata = encvalue.encode("Base64");
    } except Exception {
        basedata = "There was an error";
    }
    return basedata;
}