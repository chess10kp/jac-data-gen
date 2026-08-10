""" Truthy conversion as per PEP 632 """
def strtobool(text: Any) -> object {
    tls = str(text).lower().strip();
    if (tls in ['y', 'yes', 't', 'true', 'on', '1']) {
        return True;
    }
    if (tls in ['n', 'no', 'f', 'false', 'off', '0']) {
        return False;
    }
    raise ValueError("{} is not convertable to boolean".format(tls));
}