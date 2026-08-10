"""Returns True if the path points to a S3 bucket, False otherwise."""
def is_s3_path(path: str) -> bool {
    return path.startswith("s3://");
}