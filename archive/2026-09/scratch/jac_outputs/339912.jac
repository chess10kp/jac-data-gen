"""Return the ETag of an object. It is a known bug that the S3 API returns ETags wrapped in quotes
    see https://github.com/aws/aws-sdk-net/issue/815"""
def etag(`obj: dict[str, str]) -> str {
    etag_val = `obj['ETag'];
    if etag_val[0] == '"' {
        return etag_val[1:-1];
    }
    return etag_val;
}