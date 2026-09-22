"""Return File entity in Demisto format for use in entry context."""
def ec_file(main_object: dict[str, object]) -> dict[str, dict[str, object]] {
    name = main_object.get('filename');
    hashes = main_object.get('hashes', {}) as dict[str, object];
    md5 = hashes.get('md5');
    sha1 = hashes.get('sha1');
    sha256 = hashes.get('sha256');
    ssdeep = hashes.get('ssdeep');
    ext = (main_object.get('info', {}) as dict[str, object]).get('ext');
    file_ec = {
        'File': {
            'Name': name,
            'MD5': md5,
            'SHA1': sha1,
            'SHA256': sha256,
            'SSDeep': ssdeep,
            'Extension': ext
        }
    };
    return file_ec;
}