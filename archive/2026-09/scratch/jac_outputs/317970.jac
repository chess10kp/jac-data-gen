"""Replaces CONCAT() with CONCAT_WS(MID(CHAR(0),0,0), ...) counterpart."""
def tamper(payload: str, **kwargs: object) -> str {
    if payload {
        payload = payload.replace("CONCAT(", "CONCAT_WS(MID(CHAR(0),0,0),");
    }
    return payload;
}