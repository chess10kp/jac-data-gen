"""Updates the signature dictionary.

    Args:
        signatures (dict): Signature dictionary, which can be empty.
        v (dict): A dictionary, where the keys are:
            mime: the file mime type
            signs: a list of comma separated strings containing the offsets and the hex signatures.

    Returns:
        dict: The signature dictionary with signatures from v
    """
def update_signatures(signatures: Any, v: Any) -> object {
    mime = v.get("mime");
    signs = v.get("signs");
    for sign in signs {
        arr = sign.split(",");
        offset = arr[0];
        hex = arr[1];
        if (hex == "00") {
            continue;
        }
        offset_signatures = signatures.get(offset, {});
        offset_signatures[hex] = mime;
        signatures[offset] = offset_signatures;
    }
    return signatures;
}