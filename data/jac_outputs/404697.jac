"""Construct call_reply message for CtrlServer API responses."""
def call_reply(msg: str, call_return: str) -> dict[str, str] {
    return {"type": "call_reply", "msg": msg, "call_return": call_return};
}