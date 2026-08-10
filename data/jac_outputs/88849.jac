""" Error Code 401 """
def ERR_NOSUCHNICK(sender: str, receipient: str, message: str) -> str {
    return "ERROR from <" + sender + ">: " + message;
}