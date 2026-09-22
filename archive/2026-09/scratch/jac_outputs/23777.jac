"""Check whether a TCP response frame has no format errors."""
def check_not_errors_tcp(requets_raw: bytes, response_raw: bytes, consulta: str) -> int {
    OK = 1;
    if requets_raw[:5] != response_raw[:5] {
        OK = 0;
    }
    if len(response_raw[6:]) != int.from_bytes(response_raw[4:6], "big") {
        OK = 0;
    }
    return OK;
}