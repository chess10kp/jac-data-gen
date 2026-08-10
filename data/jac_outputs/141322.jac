"""
    Args:
        bucketName: the name of the s3 bucket
        key: S3 object key within a bucket, i.e. the path

    Returns:
        The path of the s3 object
    """
def getPath(bucketName: str, key: str) -> str {
    f's3://{bucketName}/{key}'
}