import from io { BytesIO }

"""Detect if resource is encrypted with GnuPG."""
def detect_encrypted_resource(resource: bytes | BytesIO) -> bool {
    line: bytes;
    try {
        reader = resource as BytesIO;
        line = reader.read(50);
        reader.seek(0);
    } except AttributeError {
        line = (resource as bytes)[:50];
    }
    if line.startswith(b'-----BEGIN PGP') {
        return True;
    } elif line.startswith(b'\x85\x02') {
        return True;
    } else {
        return False;
    }
}