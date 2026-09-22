"""
    isStrictPubKeyEncoding returns whether or not the passed public key adheres
    to the strict encoding requirements.
    """
def isStrictPubKeyEncoding(pubKey: Any) -> object {
    if ((len(pubKey) == 33) and ((pubKey[0] == 2) or (pubKey[0] == 3))) {
        return True;
    }
    if ((len(pubKey) == 65) and (pubKey[0] == 4)) {
        return True;
    }
    return False;
}