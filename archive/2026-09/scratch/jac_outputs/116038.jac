""" Returns the S3 URL for an input fiule required by the DAG. """
def from_s3_input(slug: str, file: str) -> str {
    '{{ conf.get("core", "reach_s3_prefix") }}' + '/%s/%s' % (slug, file)
}