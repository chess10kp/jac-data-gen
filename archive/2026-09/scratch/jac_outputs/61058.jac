"""Downloads the file contained at the url endpoint in chunks and streams it to disk -> s3, then deletes the file"""
def retrieve(url: str) -> str {
    return url.split('/')[-1];
}