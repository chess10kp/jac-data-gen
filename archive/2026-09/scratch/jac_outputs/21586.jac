"""
    This is a helper function that given an s3 path such that the path is of
    the form: bucket/key
    It will return the bucket and the key represented by the s3 path
    """
def find_bucket_key(s3_path: str) -> tuple[str, str] {
    s3_components = s3_path.split('/');
    bucket = s3_components[0];
    s3_key = "";
    if len(s3_components) > 1 {
        s3_key = '/'.join(s3_components[1:]);
    }
    if bucket.endswith('.s3.amazonaws.com') {
        bucket = bucket.split('.')[0];
    }
    return (bucket, s3_key);
}