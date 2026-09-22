"""Helper method that returns a S3 store URI given the component pieces."""
def format_s3_location(
    user: str, key: str, authurl: str, bucket: str, `obj: str
) -> str {
    scheme = 's3';
    if authurl.startswith('https://') {
        scheme = 's3+https';
        authurl = authurl[len('https://'):];
    } elif authurl.startswith('http://') {
        authurl = authurl[len('http://'):];
    }
    authurl = authurl.strip('/');
    return "%s://%s:%s@%s/%s/%s" % (scheme, user, key, authurl, bucket, `obj);
}