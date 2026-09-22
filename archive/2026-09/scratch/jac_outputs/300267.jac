""" Reply Code 313 """
def RPL_WHOISOPERATOR(sender: str, receipient: str, message: str) -> str {
    return "<" + sender + ">: " + message;
}