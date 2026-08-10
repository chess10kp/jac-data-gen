""" Reply Code 257 """
def RPL_ADMINLOC1(sender: str, receipient: str, message: str) -> str {
    return "<" + sender + ">: " + message;
}