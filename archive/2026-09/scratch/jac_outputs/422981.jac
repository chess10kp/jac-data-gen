"""Reply Code 366."""
def RPL_ENDOFNAMES(sender: str, receipient: str, message: str) -> str {
    return "<" + sender + ">: " + message;
}