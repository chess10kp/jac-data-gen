"""Reply Code 201."""
def RPL_TRACECONNECTING(sender: str, receipient: str, message: str) -> str {
    return "<" + sender + ">: " + message;
}