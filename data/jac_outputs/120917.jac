"""Reply Code 242"""
def RPL_STATSUPTIME(sender: str, receipient: str, message: str) -> str {
    return "<" + sender + ">: " + message;
}