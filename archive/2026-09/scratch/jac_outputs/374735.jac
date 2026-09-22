"""Convert an IRI ireg-name component for URI reg-name use."""
def ConvertIregName(iregname: str) -> bytes | str {
    try {
        return iregname.encode('idna');
    } except Exception {
        ;
    }
    return iregname;
}