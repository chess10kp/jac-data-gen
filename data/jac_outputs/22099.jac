""" Reply Code 207 """
def RPL_TRACESERVICE(sender: str, receipient: str, message: str) -> str {
    return "<" + sender + ">: " + message;
}