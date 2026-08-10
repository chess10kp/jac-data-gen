"""Remove AWS @-based region specification from file."""
def clean_file(f: str, config: dict[str, str]) -> str {
    (approach, rest) = f.split("://");
    (bucket_region, key) = rest.split("/", 1);
    if bucket_region.find("@") > 0 {
        (bucket, region) = bucket_region.split("@");
    } else {
        bucket = bucket_region;
    }
    if config.get("input_type") in ["http", "https"] {
        return "https://s3.amazonaws.com/%s/%s" % (bucket, key);
    }
    return "%s://%s/%s" % (approach, bucket, key);
}