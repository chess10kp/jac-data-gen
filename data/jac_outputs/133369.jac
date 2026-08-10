"""
Get bucket and file name from s3 trigger event to download transaction source data file.
"""
def _get_bucket_and_file_names(event: dict) -> tuple[str, str] {
    bucket_name = event['Records'][0]['s3']['bucket']['name'];
    file_key = event['Records'][0]['s3']['object']['key'];
    return (bucket_name, file_key);
}